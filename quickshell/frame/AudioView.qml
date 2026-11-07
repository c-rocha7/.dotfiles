// Painel de áudio (as funções do pavucontrol, via PipeWire):
//   Saída: volume/mudo do padrão + escolher o dispositivo (alto-falante, fone, HDMI, Bluetooth)
//   Entrada: volume/mudo do microfone + escolher o microfone
//   Aplicativos: volume e mudo de cada app tocando
// Perfis da placa (estéreo/HDMI etc.) não existem na API do Quickshell: botão "Avançado" → pavucontrol.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs
import qs.bar

IslandView {
    id: root

    padH: 8
    padV: 8

    readonly property var nodes: Pipewire.nodes.values
    // O Quickshell só carrega os detalhes (media.class, nome do app, volume) de um nó acompanhado
    // por um PwObjectTracker. Então: candidatos pela estrutura (já disponível) → acompanha todos →
    // filtra pela classe quando ficam prontos ("ready").
    readonly property var outCandidates: nodes.filter(n => !n.isStream && n.isSink)
    readonly property var inCandidates: nodes.filter(n => !n.isStream && !n.isSink)
    readonly property var appCandidates: nodes.filter(n => n.isStream && n.isSink)
    function kind(n) { return n?.ready ? (n.properties?.["media.class"] ?? "") : ""; }
    readonly property var sinks: outCandidates.filter(n => kind(n) === "Audio/Sink")
    readonly property var sources: inCandidates.filter(n => kind(n) === "Audio/Source")
    readonly property var apps: appCandidates.filter(n => kind(n) === "Stream/Output/Audio")

    PwObjectTracker {
        objects: root.outCandidates.concat(root.inCandidates, root.appCandidates)
    }

    Column {
        width: 320
        spacing: 6

        ThemedText { text: "Saída"; color: Theme.subtext; font.pixelSize: 12; font.bold: true }
        VolumeSlider { node: Pipewire.defaultAudioSink; icon: "" }
        Repeater {
            model: root.sinks
            AudioDevice {
                required property PwNode modelData
                node: modelData
                selected: modelData === Pipewire.defaultAudioSink
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
            }
        }

        Item { width: 1; height: 4 }
        ThemedText { text: "Entrada"; color: Theme.subtext; font.pixelSize: 12; font.bold: true }
        VolumeSlider { node: Pipewire.defaultAudioSource; icon: "" }
        Repeater {
            model: root.sources
            AudioDevice {
                required property PwNode modelData
                node: modelData
                selected: modelData === Pipewire.defaultAudioSource
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }

        Item { width: 1; height: 4 }
        ThemedText { text: "Aplicativos"; color: Theme.subtext; font.pixelSize: 12; font.bold: true }
        ThemedText {
            visible: root.apps.length === 0
            text: "Nenhum app tocando"
            color: Theme.overlay
            font.pixelSize: 12
        }
        Repeater {
            model: root.apps
            Column {
                required property PwNode modelData
                spacing: 0

                ThemedText {
                    width: 320
                    elide: Text.ElideRight
                    font.pixelSize: 12
                    text: {
                        const p = modelData.properties ?? {};
                        const app = p["application.name"] || modelData.description || modelData.name;
                        const media = p["media.name"];
                        return media && media !== app ? `${app} · ${media}` : app;
                    }
                }
                VolumeSlider { node: modelData; icon: "" }
            }
        }

        Item { width: 1; height: 4 }
        SmallButton {
            text: "Avançado (pavucontrol)"
            onClicked: {
                Audio.close();
                Quickshell.execDetached(["pavucontrol"]);
            }
        }
    }
}
