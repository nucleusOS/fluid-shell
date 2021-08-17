/*
add in ~/.config/gtk-3.0/gtk.css

decoration {
    border-width: 0px;
    box-shadow: none;
    margin: 0px;
}

I HATE GTK 3 DROP SHADOW BTW

*/

import QtQuick 2.14
import QtQuick.Window 2.14
import QtQuick.LocalStorage 2.14
import QtQuick.Layouts 1.14
import QtWayland.Compositor 1.14
/*import Liri.XWayland 1.0 as LXW*/
import "utils/settings.js" as Settings
import "utils/utils.js" as Utils
import "UI"

Item {
    property alias root: screen_loader.item

    WaylandCompositor {
        id: wayland_compositor
        WaylandOutput {
            window: Window {
                Item {
                    id: state_handler
                    state: (Settings.get("setup_done") === "true") ? "locked" : "setup"
                    states: [
                        State {
                            name: "locked"
                        },
                        State {
                            name: "normal"
                        },
                        State {
                            name: "multitasking"
                        },
                        State {
                            name: "setup"
                        }
                    ]
                }

                Component.onCompleted: {
                    Settings.getDatabase()
                    //xwayland.startServer()
                }
                visible: true
                title: qsTr("Fluid Shell - Phone Screen")
                //base screen resolution for the setup.
                width: (Settings.get("setup_done") === "true") ? Settings.get("screen_width") : 480
                height: (Settings.get("setup_done") === "true") ? Settings.get("screen_height") : 800
                id: wayland_window
                Loader {
                    id: screen_loader
                    source: (state_handler.state != "setup") ? "UI/Screen.qml" : "UI/Setup.qml"
                }
            }
        }
        XdgShell {
            onToplevelCreated: {
                shellSurfaces.append({
                    shellSurface: xdgSurface
                })
                toplevel.sendResizing(Qt.size(wayland_window.width, wayland_window.height - root.statusbar.height ))

            }
        }

        /*LXW.XWayland {
            id: xwayland
            enabled: true
            manager: LXW.XWaylandManager {
                id: manager
                onShellSurfaceRequested: {
                    var shellSurface = shellSurfaceComponent.createObject(manager);
                    shellSurface.initialize(manager, window, geometry, overrideRedirect, parentShellSurface);
                }
                onShellSurfaceCreated: {
                    shellSurfaces.append({
                        shellSurface: shellSurface
                    })
                    shellSurface.sendResize(Qt.size(480, 800));
                }
            }
            Component {
                id: shellSurfaceComponent
                LXW.XWaylandShellSurface {}
            }
        }*/
        XdgDecorationManagerV1 {
            preferredMode: XdgToplevel.ServerSideDecoration
        }
        ListModel {
            id: shellSurfaces
        }
    }
}
