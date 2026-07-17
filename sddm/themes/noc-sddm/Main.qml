//
// Tema SDDM minimalista: wallpaper, lista de usuarios e seletor de sessao.
//

import QtQuick 2.0
import SddmComponents 2.0
import "./components"

Rectangle {
    id: root

    width: 1024
    height: 768

    property int sessionIndex: sessionSelector.index

    readonly property int userCardWidth: 140
    readonly property int userCardSpacing: 20
    readonly property int userRowWidth: userModel.count > 0
        ? userModel.count * userCardWidth + (userModel.count - 1) * userCardSpacing
        : 0

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    TextConstants { id: textConstants }

    Connections {
        target: sddm

        function onLoginFailed() {
            showStatus(textConstants.loginFailed, "#e53935")
            passwordField.text = ""
        }

        function onLoginSucceeded() {
            showStatus(textConstants.loginSucceeded, "#43a047")
        }

        function onInformationMessage(message) {
            showStatus(message, "#e53935")
        }
    }

    function showStatus(message, color) {
        statusMessage.text = message
        statusMessage.color = color
        statusMessage.visible = true
    }

    function tryLogin() {
        if (userList.currentIndex < 0 || !userList.currentItem)
            return

        sddm.login(
            userList.currentItem.userName,
            passwordField.text,
            sessionSelector.index
        )
    }

    function focusPasswordIfNeeded() {
        passwordField.text = ""

        if (userList.currentItem && userList.currentItem.needsPassword)
            passwordField.focus = true
    }

    Repeater {
        model: screenModel

        Item {
            Image {
                x: geometry.x
                y: geometry.y
                width: geometry.width
                height: geometry.height
                source: config.background ? config.background : ""
                fillMode: Image.PreserveAspectCrop
                visible: source !== ""
                smooth: true
            }

            Rectangle {
                x: geometry.x
                y: geometry.y
                width: geometry.width
                height: geometry.height
                color: "#1A237E"
                visible: !config.background || config.background === ""
            }
        }
    }

    Component {
        id: userDelegate

        Item {
            width: root.userCardWidth

            property string userName: model.name
            property bool needsPassword: model.needsPassword
            height: userList.height

            UserCard {
                id: userCard

                anchors.centerIn: parent
                userName: model.name
                displayName: model.realName !== "" ? model.realName : model.name
                iconSource: model.icon
                needsPassword: model.needsPassword
                active: userList.currentIndex === index

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onPressed: userCard.pressed = true
                    onReleased: userCard.pressed = false
                    onCanceled: userCard.pressed = false

                    onClicked: {
                        userList.currentIndex = index
                        userList.focus = true

                        if (!model.needsPassword)
                            root.tryLogin()
                        else
                            focusPasswordIfNeeded()
                    }
                }
            }
        }
    }

    Column {
        id: loginArea

        width: root.userRowWidth
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -20
        spacing: 24

        ListView {
            id: userList

            width: parent.width
            height: 150
            orientation: ListView.Horizontal
            spacing: root.userCardSpacing
            clip: false
            focus: true
            model: userModel
            delegate: userDelegate
            currentIndex: userModel.lastIndex

            onCurrentIndexChanged: {
                if (userList.currentItem && userList.currentItem.needsPassword)
                    focusPasswordIfNeeded()
            }
        }

        PasswordBox {
            id: passwordField

            width: parent.width
            height: 36
            visible: userList.currentItem && userList.currentItem.needsPassword
            opacity: visible ? 1 : 0

            color: "#ffffff"
            borderColor: "#ffffff66"
            focusColor: "#ffffff"
            hoverColor: "#ffffff"
            textColor: "#1a1a1a"
            font.pixelSize: 14

            Keys.onPressed: function (event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.tryLogin()
                    event.accepted = true
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }

        Text {
            id: statusMessage

            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: "#ffffff"
            font.pixelSize: 15
            visible: false
            text: ""
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: textConstants.session
            color: "#ffffffcc"
            font.pixelSize: 13
            font.bold: true
        }

        SessionComboBox {
            id: sessionSelector

            model: sessionModel
            font.pixelSize: 14
            visible: sessionModel.count > 0

            Component.onCompleted: {
                if (sessionModel.count > 0)
                    index = sessionModel.lastIndex
            }
        }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        spacing: 12

        PowerButton {
            // Qt.resolvedUrl resolve relativo ao Main.qml (raiz do tema),
            // não ao PowerButton.qml (components/), senão o ícone some.
            icon: Qt.resolvedUrl("images/ic_restart_white_24px.svg")
            visible: sddm.canReboot
            onClicked: sddm.reboot()
        }

        PowerButton {
            icon: Qt.resolvedUrl("images/ic_power_settings_new_white_24px.svg")
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()
        }
    }

    Component.onCompleted: {
        userList.focus = true
        focusPasswordIfNeeded()
    }
}
