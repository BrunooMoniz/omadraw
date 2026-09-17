import QtQuick

Rectangle {
    id: root
    property bool light: false
    property bool glassDemo: false
    readonly property color ink: light ? "#202b3a" : "#e9f0e7"
    readonly property color muted: light ? "#64748b" : "#91a28e"
    readonly property color card: light ? "#ffffff" : "#202b22"
    color: light ? "#dde6f0" : "#0e1917"
    gradient: Gradient {
        GradientStop { position: 0; color: root.light ? "#e5ecf7" : "#122422" }
        GradientStop { position: 1; color: root.light ? "#dbe9df" : "#182016" }
    }
    component Label: Text { font.family: "DejaVu Sans"; color: root.ink }
    Label { x: 68; y: 44; text: "EXAMPLE WORKSPACE"; font.pixelSize: 13; font.letterSpacing: 3; color: root.muted }
    Label { x: 1056; y: 45; text: "DEMO DATA"; font.pixelSize: 12; font.letterSpacing: 2; color: root.muted }
    Rectangle {
        x: 68; y: 97; width: root.glassDemo ? 1464 : 1155; height: 797; radius: 20
        color: root.light ? "#f4f7fc" : "#141d19"
        border.color: root.light ? "#c7d2e3" : "#334437"
        Row {
            x: 30; y: 26; spacing: 8
            Repeater { model: ["#ff665d", "#ffc452", "#41c96e"]; Rectangle { required property color modelData; width: 9; height: 9; radius: 5; color: modelData } }
        }
        Label { x: 365; y: 20; text: "Studio / Example project"; color: root.muted; font.pixelSize: 15 }
        Rectangle { x: 0; y: 58; width: parent.width; height: 1; color: root.light ? "#dde4ee" : "#2a382e" }
        Label { x: 43; y: 90; text: "A little clarity goes a long way."; font.pixelSize: 33; font.weight: Font.DemiBold }
        Label { x: 44; y: 143; text: "Review the idea. Highlight what matters. Share the next step."; color: root.muted; font.pixelSize: 17 }
        Row {
            x: 44; y: 217; spacing: 23
            Repeater {
                model: [ {step:"01", title:"Sketch the idea", body:"A simple starting point.", tag:"DRAFT"}, {step:"02", title:"Find the focus", body:"Make the important part clear.", tag:"IN REVIEW"}, {step:"03", title:"Share the result", body:"One image. One clear message.", tag:"READY"} ]
                Rectangle {
                    required property var modelData
                    width: 340; height: 184; radius: 13; color: root.card
                    Label { x: 23; y: 21; text: parent.modelData.step; color: root.muted; font.pixelSize: 13 }
                    Label { x: 23; y: 60; text: parent.modelData.title; font.pixelSize: 22; font.weight: Font.DemiBold }
                    Label { x: 23; y: 99; text: parent.modelData.body; color: root.muted; font.pixelSize: 14 }
                    Label { x: 23; y: 145; text: parent.modelData.tag; color: root.light ? "#23589d" : "#c6f24e"; font.pixelSize: 10; font.letterSpacing: 1.5 }
                }
            }
        }
        Label { x: 44; y: 465; text: "A small plan"; font.pixelSize: 23; font.weight: Font.DemiBold }
        Column {
            x: 45; y: 519; spacing: 23
            Repeater {
                model: ["Explore a few directions", "Choose the detail to improve", "Turn feedback into the next version"]
                Row {
                    required property string modelData
                    spacing: 16
                    Rectangle { width: 17; height: 17; radius: 4; color: "transparent"; border.color: root.muted }
                    Label { y: -3; text: parent.modelData; font.pixelSize: 16; color: root.muted }
                }
            }
        }
        Rectangle { x: 720; y: 469; width: 368; height: 205; radius: 14; color: root.card
            Label { x: 24; y: 24; text: "Less explaining.\nMore showing."; font.pixelSize: 27; lineHeight: 1.2; font.weight: Font.DemiBold }
            Label { x: 24; y: 130; text: "A visual note can be enough."; color: root.muted; font.pixelSize: 15 }
        }
        Column {
            visible: root.glassDemo
            x: 1190; y: 218; spacing: 30
            Repeater {
                model: 10
                Column {
                    required property int index
                    spacing: 10
                    Label { text: "Example note " + (parent.index + 1); font.pixelSize: 16; color: root.muted }
                    Rectangle { width: 209; height: 2; color: root.light ? "#bdc9b6" : "#405c48" }
                }
            }
        }
        Label { x: 44; y: 741; text: "Illustrative workspace. All content is fictional."; color: root.muted; font.pixelSize: 12 }
    }
}
