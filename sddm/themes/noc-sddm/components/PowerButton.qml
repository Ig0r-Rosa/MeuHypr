//
// Botão quadrado de energia (reiniciar / desligar) para o canto da tela.
// Fundo translúcido escuro para destacar o ícone branco sobre o wallpaper.
//

import QtQuick 2.0

Rectangle {
    id: btn

    property alias icon: iconImage.source
    signal clicked()

    width: 48
    height: 48
    radius: 8

    color: "#00000066"
    border.color: "#ffffff59"
    border.width: 1

    Image {
        id: iconImage

        anchors.centerIn: parent
        width: 24
        height: 24
        sourceSize.width: 24
        sourceSize.height: 24
        smooth: true
        fillMode: Image.PreserveAspectFit
    }

    states: State {
        name: "hover"
        PropertyChanges {
            target: btn
            color: "#000000aa"
            border.color: "#ffffffcc"
        }
    }

    transitions: Transition {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: btn.state = "hover"
        onExited: btn.state = ""
        onClicked: btn.clicked()
    }
}
