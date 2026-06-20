//
// Seletor de sessao com menu que abre para cima.
//

import QtQuick 2.0

FocusScope {
    id: container

    width: 260
    height: 40

    property color panelColor: "#1a1a2ecc"
    property color panelBorder: "#ffffff55"
    property color hoverColor: "#ffffff"
    property color textColor: "#ffffff"
    property color hoverTextColor: "#1a1a1a"
    property color accentColor: "#7986CB"

    readonly property int cornerRadius: 10
    readonly property int itemRadius: 8
    readonly property int menuPadding: 4

    property alias model: listView.model
    property int index: 0
    property font font

    signal valueChanged(int id)

    onFocusChanged: if (!container.activeFocus) close(false)

    Rectangle {
        id: mainPanel

        anchors.fill: parent
        radius: cornerRadius
        color: panelColor
        border.color: dropDownOpen ? accentColor : panelBorder
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 10
            spacing: 8

            Text {
                id: selectedLabel
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - arrowIcon.width - 8
                color: textColor
                font: container.font
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Image {
                id: arrowIcon
                width: 20
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                source: Qt.resolvedUrl("../images/ic_arrow_drop_down_white_24px.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true
                rotation: dropDownOpen ? 180 : 0

                Behavior on rotation {
                    NumberAnimation { duration: 150 }
                }
            }
        }
    }

    property bool dropDownOpen: dropDown.state === "visible"

    MouseArea {
        anchors.fill: container
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            container.focus = true
            toggle()
        }

        onWheel: {
            var next = container.index
            if (wheel.angleDelta.y > 0)
                next = Math.max(0, next - 1)
            else
                next = Math.min(listView.count - 1, next + 1)
            applyIndex(next)
        }
    }

    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Up) {
            applyIndex(Math.max(0, container.index - 1))
        } else if (event.key === Qt.Key_Down) {
            if (event.modifiers !== Qt.AltModifier)
                applyIndex(Math.min(listView.count - 1, container.index + 1))
            else
                toggle()
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            close(true)
        } else if (event.key === Qt.Key_Escape) {
            close(false)
        }
    }

    Rectangle {
        id: dropDown

        width: container.width
        height: 0
        anchors.bottom: container.top
        anchors.bottomMargin: 6

        radius: cornerRadius
        color: panelColor
        border.color: accentColor
        border.width: 1
        clip: true

        ListView {
            id: listView
            anchors.fill: parent
            anchors.margins: menuPadding
            spacing: 2
            interactive: count > 4

            delegate: Rectangle {
                width: listView.width
                height: container.height - menuPadding
                radius: itemRadius
                color: previewIndex === index ? hoverColor : "transparent"

                property string itemName: model.name
                property bool highlighted: previewIndex === index

                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    color: parent.highlighted ? hoverTextColor : textColor
                    font: container.font
                    text: parent.itemName
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter

                    Behavior on color {
                        ColorAnimation { duration: 120 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: previewIndex = index
                    onClicked: {
                        applyIndex(index)
                        close(true)
                    }
                }
            }
        }

        states: [
            State {
                name: "visible"
                PropertyChanges {
                    target: dropDown
                    height: container.height * listView.count
                        + menuPadding * 2
                        + Math.max(0, listView.count - 1) * listView.spacing
                        + 2
                }
            }
        ]

        transitions: Transition {
            NumberAnimation {
                property: "height"
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    property int previewIndex: container.index

    function applyIndex(newIndex) {
        if (newIndex < 0 || newIndex >= listView.count)
            return
        container.index = newIndex
        previewIndex = newIndex
        listView.currentIndex = newIndex
        refreshLabel()
        valueChanged(newIndex)
    }

    function toggle() {
        if (dropDown.state === "visible")
            close(false)
        else
            open()
    }

    function refreshLabel() {
        listView.currentIndex = container.index
        if (listView.currentItem)
            selectedLabel.text = listView.currentItem.itemName
    }

    function open() {
        previewIndex = container.index
        listView.currentIndex = container.index
        dropDown.state = "visible"
    }

    function close(update) {
        dropDown.state = ""

        if (update)
            applyIndex(previewIndex)
        else
            previewIndex = container.index
    }

    Component.onCompleted: {
        refreshLabel()
    }

    onIndexChanged: {
        previewIndex = container.index
        refreshLabel()
    }

    onModelChanged: {
        if (container.index >= listView.count)
            container.index = Math.max(0, listView.count - 1)
        refreshLabel()
    }
}
