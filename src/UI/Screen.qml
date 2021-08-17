import QtQuick 2.14
import QtQuick.LocalStorage 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import QtWayland.Compositor 1.14

import "../utils/settings.js" as Settings
import "../utils/utils.js" as Utils
import "../UI"

Rectangle {
    property var appPages: []
    property int margin_padding: root.height / (50 * Settings.get("applications_per_row"))
    property alias statusbar: statusbar
    Component.onCompleted: {
        Settings.getDatabase()
        statusbar.battery_percentage.text = battery_handler.battery_level() + "%"
        Utils.handle_battery_monitor(statusbar.battery_container, statusbar.battery_level)
    }
    id: root
    width: wayland_window.width
    height: wayland_window.height
    visible: true
    LockScreen {
        id: lockscreen
        width: root.width
        height: root.height
        visible: true
        z: 2000
    }

    Rectangle {
        width: root.width
        height: root.height
        visible: true
        color: "black"
        Component.onCompleted: {
            Utils.application_list_refresh(application_list)
        }
        StatusBar {
            id: statusbar
        }
        Rectangle {
            color: "transparent"
            visible: (shellSurfaces.count > 0) ? true : false
            id: application_container
            width: parent.width
            height: parent.height - statusbar.height
            y: statusbar.height
            z: (application_container.visible == true) ? 200 : 0
            StackLayout {
                id: application_display
                anchors.fill: parent
                Repeater {
                    id: application_repeater
                    model: shellSurfaces
                    delegate: Loader {
                        source: (modelData.toString().match(/XWaylandShellSurface/)) ? "../../Chromes/XWaylandChrome.qml" : "../../Chromes/WaylandChrome.qml"
                        Component.onCompleted: {
                            application_display.currentIndex = application_display.count - 1
                            application_container.y = statusbar.height
                        }
                        Component.onDestruction: {
                            application_display.currentIndex--
                            if(!shellSurfaces.count > 0) {
                                application_container.visible = false
                            }
                        }
                    }
                }
            }

        }
        SwipeView {
            id: screen_swipe_view
            currentIndex: 1
            anchors.fill: parent
            Item {
                id: information_page
                Text {
                    visible: true
                    text: "Coming soon!"
                    anchors {
                        verticalCenter: parent.verticalCenter
                        horizontalCenter: parent.horizontalCenter
                    }
                    color: "white"
                    font.pixelSize: parent.height / 25
                }
            }
            Item {
                id: app_page
                GridView {
                    id: application_list
                    x: margin_padding
                    width: screen_swipe_view.width - margin_padding
                    height: screen_swipe_view.height - statusbar.height - margin_padding
                    model: appPages[0].length
                    cellWidth: (screen_swipe_view.width - margin_padding) / Settings.get("applications_per_row")
                    cellHeight: (screen_swipe_view.width - margin_padding) / Settings.get("applications_per_row")
                    focus: true
                    anchors {
                        top: statusbar.bottom
                        topMargin: margin_padding
                    }

                    delegate: Item {
                        Column {
                            id: app_rectangle
                            Rectangle {
                                color: "#00000000"
                                width: application_list.cellWidth - margin_padding
                                height: application_list.cellHeight - margin_padding
                                anchors.horizontalCenter: parent.horizontalCenter

                                Image {
                                    width: app_rectangle.height / 2.5 * Settings.get("scaling_factor")
                                    height: app_rectangle.height / 2.5 * Settings.get("scaling_factor")
                                    id: application_icon
                                    y: 20
                                    source: "image://icons/" + appPages[0][index][1]
                                    anchors {
                                        horizontalCenter: parent.horizontalCenter
                                        verticalCenter: parent.verticalCenter
                                    }
                                }
                                Text {
                                    font.pixelSize: parent.height / 10 * Settings.get("scaling_factor")
                                    text: appPages[0][index][0]
                                    color: "#ffffff"
                                    anchors {
                                        bottom: parent.bottom
                                        bottomMargin: margin_padding
                                        leftMargin: margin_padding
                                        horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        application_container.visible = true
                                        proc.start(appPages[0][index][2])
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Item {
                id: app_switcher_page
                Text {
                    visible: (shellSurfaces.count === 0)
                    text: "Nothing open yet"
                    anchors {
                        verticalCenter: parent.verticalCenter
                        horizontalCenter: parent.horizontalCenter
                    }
                    color: "#ffffff"
                    opacity: 0.4
                    font.pixelSize: parent.height / 30
                }

                GridView {
                    id: app_switcher_grid
                    x:15 * margin_padding / 2
                    y: statusbar.height + 10 * margin_padding
                    width: parent.width
                    height: parent.height - statusbar.height
                    cellWidth: parent.width / 2
                    cellHeight: parent.height / 2
                    model: shellSurfaces
                    anchors {
                        top: statusbar.bottom
                        topMargin: margin_padding
                    }
                    delegate: Item {
                        width: app_switcher_grid.cellWidth - 15 * margin_padding
                        height: app_switcher_grid.cellHeight - 10 * margin_padding
                        Text {
                            id: app_switcher_title
                            color: "#ffffff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: app_switcher_surfaceItem.top
                            anchors.bottomMargin: margin_padding
                            text: (modelData.toplevel.title.toString().length > 16) ? modelData.toplevel.title.toString().substring(0,16) + "..." : modelData.toplevel.title
                            font.pixelSize: root.height / 50
                        }

                        ShellSurfaceItem {
                            id: app_switcher_surfaceItem
                            inputEventsEnabled: false
                            shellSurface: modelData
                            width: parent.width
                            height: parent.height - app_switcher_title.height
                            anchors.bottom: parent.bottom
                            sizeFollowsSurface: false
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {

                                    application_display.currentIndex = index
                                    application_container.y = statusbar.height
                                    application_container.visible = true
                                    screen_swipe_view.currentIndex = 1
                                }
                               onPressAndHold: {
                                   modelData.surface.client.close()
                               }
                            }
                        }
                    }
                }
            }
        }
        Item {
            width: parent.width
            z: 1000
            height: 15 * Settings.get("scaling_factor")
            anchors.bottom: parent.bottom
            MouseArea {
                anchors.fill: parent
                drag.target: application_container
                drag.axis: Drag.YAxis
                drag.maximumY: root.height
                onReleased: {
                    if(-application_container.y > root.height / 3) {
                        slide.start()
                    } else {
                        bounce.start()
                    }
                }
            }
        }

        NumberAnimation {
            id: slide
            target: application_container
            properties: "y"
            to: -root.height
            easing.type: Easing.OutQuad
            duration: 200
        }
        NumberAnimation {
            id: bounce
            target: application_container
            properties: "y"
            to: statusbar.height
            easing.type: Easing.OutQuad
            duration: 200
        }
        //battery handler timer
        //TODO better "battery path" handler
        //TODO better battery indicator implementation
        Timer {
            repeat: true
            interval: 1000
            running: true
            onTriggered: {
                statusbar.battery_percentage.text = battery_handler.battery_level() + "%"
                Utils.handle_battery_monitor(statusbar.battery_container, statusbar.battery_level)
            }
        }

    }
}
