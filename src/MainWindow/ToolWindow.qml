import QtQuick
import QtQuick.Window

Window {
    id: root

    width: 1200
    height: 800
    visible: true

    property string toolTitle
    property string toolSource
    property string toolIcon

    property var mainWindow

    title: toolTitle

    Loader {
        id: loader
        anchors.fill: parent

        Component.onCompleted: {
            loader.setSource(root.toolSource, {mainWindow: root.mainWindow})
        }
    }

    function onClosing(close){
        destroy()
    }
}