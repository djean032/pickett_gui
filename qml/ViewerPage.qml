import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Pickett 1.0

Page {
    id: page
    property var dataModel
    signal back()
    focus: true

    SpectralFileService {
        id: spectralFileService
    }

    onDataModelChanged: {
        if (dataModel) {
            dataModel.fileService = spectralFileService
        }
    }

    Component.onCompleted: {
        if (dataModel) {
            dataModel.fileService = spectralFileService
        }
    }

    CatalogData {
        id: catalogData
        fileService: spectralFileService
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            spacing: 10

            Button {
                text: qsTr("← Back")
                focusPolicy: Qt.NoFocus
                onClicked: page.back()
            }

            Button {
                text: dataModel && dataModel.isLoading ? qsTr("Loading Spectrum...") : qsTr("Load Spectrum")
                focusPolicy: Qt.NoFocus
                enabled: !dataModel || !dataModel.isLoading
                onClicked: spectrumFileDialog.open()
            }

            Button {
                text: catalogData.isLoading ? qsTr("Loading Catalog...") : qsTr("Load Catalog")
                focusPolicy: Qt.NoFocus
                enabled: !catalogData.isLoading
                onClicked: catalogFileDialog.open()
            }

            Label {
                text: dataModel ? dataModel.fileName : qsTr("No file loaded")
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        Rectangle {
            visible: (dataModel && dataModel.hasError) || catalogData.hasError
            Layout.fillWidth: true
            color: "#ffe8e8"
            border.color: "#d06a6a"
            border.width: 1
            radius: 4
            implicitHeight: errorText.implicitHeight + 16

            Text {
                id: errorText
                anchors.fill: parent
                anchors.margins: 8
                color: "#8c1f1f"
                wrapMode: Text.Wrap
                text: {
                    var messages = []
                    if (dataModel && dataModel.hasError) {
                        messages.push("Spectrum: " + dataModel.errorMessage)
                    }
                    if (catalogData.hasError) {
                        messages.push("Catalog: " + catalogData.errorMessage)
                    }
                    return messages.join("\n")
                }
            }
        }

        Rectangle {
            visible: (dataModel && dataModel.hasWarning) || catalogData.hasWarning
            Layout.fillWidth: true
            color: "#fff6dd"
            border.color: "#c99a2e"
            border.width: 1
            radius: 4
            implicitHeight: warningText.implicitHeight + 16

            Text {
                id: warningText
                anchors.fill: parent
                anchors.margins: 8
                color: "#6a4a07"
                wrapMode: Text.Wrap
                text: {
                    var messages = []
                    if (dataModel && dataModel.hasWarning) {
                        messages.push("Spectrum: " + dataModel.warningMessage)
                    }
                    if (catalogData.hasWarning) {
                        messages.push("Catalog: " + catalogData.warningMessage)
                    }
                    return messages.join("\n")
                }
            }
        }

        SpectrumPlot {
            id: spectrumPlot
            Layout.fillWidth: true
            Layout.fillHeight: true
            spectrumData: dataModel
            catalogData: catalogData
        }
    }

    Keys.forwardTo: [spectrumPlot]

    FileDialog {
        id: spectrumFileDialog
        title: qsTr("Load Spectrum")
        nameFilters: ["All files (*.*)"]
        onAccepted: {
            console.log("Spectrum FileDialog accepted, selectedFile:", selectedFile)
            if (dataModel) {
                console.log("Calling loadFile with:", selectedFile.toString())
                dataModel.loadFile(selectedFile)
            } else {
                console.log("ERROR: dataModel is null")
            }
        }
    }

    FileDialog {
        id: catalogFileDialog
        title: qsTr("Load Catalog")
        nameFilters: ["CAT files (*.cat)", "All files (*.*)"]
        onAccepted: {
            console.log("Catalog FileDialog accepted, selectedFile:", selectedFile)
            if (catalogData) {
                console.log("Calling loadFile with:", selectedFile.toString())
                catalogData.loadFile(selectedFile)
            } else {
                console.log("ERROR: catalogData is null")
            }
        }
    }
}
