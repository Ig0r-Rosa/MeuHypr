//
// Cartao de usuario com avatar quadrado, borda escura e animacao ao selecionar.
//

import QtQuick 2.0

FocusScope {
    id: container

    width: 140
    height: 150
    clip: false

    property alias displayName: nameLabel.text
    property alias iconSource: avatarImage.source
    property string userName: ""
    property bool needsPassword: true
    property bool active: false
    property bool pressed: false

    readonly property int avatarSize: 110
    readonly property real avatarScale: active ? 1.14 : 1.0
    readonly property int borderWidth: 3
    readonly property int cornerRadius: 0

    Column {
        width: container.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Item {
            id: avatarFrame

            width: avatarSize
            height: avatarSize
            anchors.horizontalCenter: parent.horizontalCenter
            scale: pressed ? avatarScale * 0.94 : avatarScale
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: pressed ? 90 : 220
                    easing.type: pressed ? Easing.OutQuad : Easing.OutBack
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: cornerRadius
                color: "#000000"
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: borderWidth
                radius: Math.max(0, cornerRadius - borderWidth)
                color: "#e0e0e0"
                clip: true

                Image {
                    id: avatarImage
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    cache: false
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: cornerRadius
                color: "transparent"
                border.color: active ? "#ffffff" : "transparent"
                border.width: 2

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }
            }
        }

        Text {
            id: nameLabel
            width: avatarSize
            anchors.horizontalCenter: parent.horizontalCenter
            color: active ? "#ffffff" : "#dddddd"
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight

            Behavior on color {
                ColorAnimation { duration: 150 }
            }
        }
    }
}
