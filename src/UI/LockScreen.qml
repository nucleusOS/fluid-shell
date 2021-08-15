import QtQuick 2.14
import QtQuick.LocalStorage 2.14
import "../utils/utils.js" as Utils
import "../utils/settings.js" as Settings

Item {
    StatusBar {
        id: statusbar
    }
    Rectangle {
        Component.onCompleted: {
            Settings.getDatabase()
            Utils.handle_battery_monitor(statusbar.battery_container, statusbar.battery_level)
        }
        id: lockscreen_image
        width: root.width
        height: root.height
        color: "black"
    }
    Rectangle {
        id: lockscreen_overlay
        width: root.width
        height: root.height
        color: "#00000000"

        Text {
            id: lockscreen_time
            text: Qt.formatDateTime(new Date(), "HH:mm")
            color: 'white'
            font.pointSize: (parent.height / 30) * Settings.get("scaling_factor")
            anchors {
                left: parent.left
                bottom: lockscreen_date.top
                leftMargin: (parent.height / 26) * Settings.get("scaling_factor")
            }
        }
        Text {
            id: lockscreen_date
            text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
            color: 'white'
            font.pointSize: (parent.height / 50) * Settings.get("scaling_factor")
            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: (parent.height / 26) * Settings.get("scaling_factor")
            }
        }
        Timer {
            repeat: (state_handler.state === "locked") ? true : false
            interval: 1000
            running: true
            onTriggered: {
                lockscreen_time.text = Qt.formatDateTime(new Date(), "HH:mm");
                lockscreen_date.text = Qt.formatDateTime(new Date(), "dddd, MMMM d");
            }
        }
        MouseArea {
            id: lockscreen_mouse_area
            anchors.fill: parent
            drag.target: lockscreen_overlay
            drag.axis: Drag.YAxis
            drag.maximumY: 0
            onReleased: {
                if(lockscreen_overlay.y > -root.height / 2) {
                    bounce.restart()
                } else {
                    state_handler.state = "normal"
                    lockscreen_overlay.y = 0
                }
            }
        }
        NumberAnimation {
            id: bounce
            target: lockscreen_overlay
            properties: "y"
            to: 0
            easing.type: Easing.InOutQuad
            duration: 200
        }
    }

    Timer {
        repeat: true
        interval: 1000
        running: true
        onTriggered: {
            Utils.handle_battery_monitor(statusbar.battery_container, statusbar.battery_level)
        }
    }
}

