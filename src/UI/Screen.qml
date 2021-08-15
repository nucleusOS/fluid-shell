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
    property alias bottombar: bottombar
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
        visible: (state_handler.state === "locked")
    }

    Rectangle {
        width: root.width
        height: root.height
        visible: (state_handler.state === "normal")
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
            height: parent.height - statusbar.height - bottombar.height
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
                            application_container.visible = true
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
                    font.pointSize: parent.height / 25
                }
            }
            Item {
                id: app_page
                GridView {
                    id: application_list
                    x: margin_padding
                    width: screen_swipe_view.width - margin_padding
                    height: screen_swipe_view.height - statusbar.height - margin_padding - bottombar.height
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
                                        left: parent.left
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
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
                    text: "No open applications"
                    anchors {
                        verticalCenter: parent.verticalCenter
                        horizontalCenter: parent.horizontalCenter
                    }
                    color: "white"
                    font.pointSize: parent.height / 25
                }

                GridView {
                    id: app_switcher_grid
                    x: margin_padding
                    y: statusbar.height + margin_padding
                    width: parent.width
                    height: parent.height - statusbar.height - bottombar.height
                    cellWidth: parent.width / 2
                    cellHeight: parent.height / 2
                    model: shellSurfaces
                    anchors {
                        top: statusbar.bottom
                        topMargin: margin_padding
                    }
                    delegate: ShellSurfaceItem {
                        inputEventsEnabled: false
                        shellSurface: modelData
                        width: app_switcher_grid.cellWidth - 2 * margin_padding
                        height: app_switcher_grid.cellHeight - margin_padding
                        sizeFollowsSurface: false
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                application_display.currentIndex = index
                                application_container.visible = true
                            }
                        }
                        Rectangle {
                            width: 25 * Settings.get("scaling_factor")
                            radius: width*0.5
                            height: 25 * Settings.get("scaling_factor")
                            color: "gray"
                            anchors { right: parent.right; top: parent.top}
                            Text {
                                anchors {
                                    verticalCenter: parent.verticalCenter
                                    horizontalCenter: parent.horizontalCenter
                                }
                                text: "x"
                                font.pointSize: 10 * Settings.get("scaling_factor")
                                color: "red"
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    modelData.surface.client.close()
                                }
                            }
                        }
                    }
                }
            }
        }

        BottomBar {
            id: bottombar
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
