pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// Owns org.freedesktop.Notifications (stop dunst/mako first). Keeps a history list for the
// notification centre and a short-lived popup list for toasts.
Singleton {
    id: root

    property bool dnd: false
    property int tick: 0
    property var live: ({})

    readonly property ListModel history: historyModel
    readonly property ListModel popups: popupModel
    readonly property int count: historyModel.count

    ListModel { id: historyModel }
    ListModel { id: popupModel }

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const critical = n.urgency === NotificationUrgency.Critical;
            const item = {
                nid: n.id,
                appName: n.appName || "",
                appIcon: n.appIcon || "",
                image: n.image || "",
                summary: n.summary || "",
                body: n.body || "",
                urgency: n.urgency,
                time: Date.now(),
                timeout: critical ? 0 : (n.expireTimeout > 0 ? n.expireTimeout * 1000 : 6000)
            };
            root.live[n.id] = n;
            historyModel.insert(0, item);
            if (historyModel.count > 100) historyModel.remove(100, historyModel.count - 100);
            if (!root.dnd || critical) popupModel.insert(0, item);
            n.closed.connect(() => root.dismissPopup(item.nid));
        }
    }

    function indexOfId(model, nid) {
        for (let i = 0; i < model.count; i++)
            if (model.get(i).nid === nid) return i;
        return -1;
    }

    function dismissPopup(nid) {
        const i = indexOfId(popupModel, nid);
        if (i >= 0) popupModel.remove(i);
    }

    function remove(nid) {
        dismissPopup(nid);
        const i = indexOfId(historyModel, nid);
        if (i >= 0) historyModel.remove(i);
        const n = live[nid];
        if (n) { try { n.dismiss(); } catch (e) {} delete live[nid]; }
    }

    function clearAll() {
        popupModel.clear();
        historyModel.clear();
        for (const k of Object.keys(live)) { try { live[k].dismiss(); } catch (e) {} }
        live = ({});
    }

    function invokeDefault(nid) {
        const n = live[nid];
        if (!n) return;
        for (let i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === "default") { n.actions[i].invoke(); return; }
        }
    }

    function iconSource(appIcon) {
        if (!appIcon) return Quickshell.iconPath("dialog-information");
        if (appIcon.startsWith("/")) return "file://" + appIcon;
        return Quickshell.iconPath(appIcon, "dialog-information");
    }

    function ago(t, _tick) {
        const s = Math.floor((Date.now() - t) / 1000);
        if (s < 45) return "now";
        if (s < 3600) return Math.max(1, Math.round(s / 60)) + "m ago";
        if (s < 86400) return Qt.formatDateTime(new Date(t), "HH:mm");
        return Qt.formatDateTime(new Date(t), "d MMM HH:mm");
    }

    Timer { interval: 30000; running: historyModel.count > 0; repeat: true; onTriggered: root.tick++ }
}
