import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "custom.screenshots"

  property var screenshots: []
  property var latestScreenshot: null
  property var currentScreenshot: null
  property int totalCount: 0
  property string currentTab: "latest" // "latest" | "history"
  property bool popupOpen: false
  property string toastMessage: ""
  property string toastType: "info" // "info" | "success" | "urgent"
  property bool confirmDelete: false
  property string deleteTargetPath: ""

  function showToast(msg, type) {
    toastMessage = msg
    toastType = type || "success"
    toastTimer.restart()
  }

  Timer {
    id: toastTimer
    interval: 3500
    onTriggered: root.toastMessage = ""
  }

  function refresh() {
    listProc.running = true
  }

  function triggerCapture(mode) {
    root.popupOpen = false
    captureProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--capture", mode || "smart"]
    captureProc.running = true
  }

  function copyPath(fpath) {
    if (!fpath) return
    copyPathProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--copy-path", fpath]
    copyPathProc.running = true
    showToast("📋 Sökvägen kopierad! Klistra in direkt till AI/Claude/Gemini.", "success")
  }

  function copyImage(fpath) {
    if (!fpath) return
    copyImageProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--copy-image", fpath]
    copyImageProc.running = true
    showToast("🖼️ Bilddata kopierad till urklipp!", "success")
  }

  function editImage(fpath) {
    if (!fpath) return
    root.popupOpen = false
    editProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--edit", fpath]
    editProc.running = true
  }

  function viewImage(fpath) {
    if (!fpath) return
    viewProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--view", fpath]
    viewProc.running = true
  }

  function askDelete(fpath) {
    deleteTargetPath = fpath
    confirmDelete = true
  }

  function doDelete(fpath) {
    confirmDelete = false
    if (!fpath) return
    deleteProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--delete", fpath]
    deleteProc.running = true
    showToast("🗑️ Skärmdumpen raderades.", "urgent")
  }

  implicitWidth: contentRow.implicitWidth + Style.space(16)
  implicitHeight: barSize

  // ---------------------------------------------------------------------------
  // 1. Process Handlers
  // ---------------------------------------------------------------------------
  Process {
    id: listProc
    command: ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--list"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var data = JSON.parse(text.trim())
          if (data && data.ok) {
            root.screenshots = data.history || []
            root.latestScreenshot = data.latest || null
            root.totalCount = data.total_count || 0
            if (!root.currentScreenshot && root.latestScreenshot) {
              root.currentScreenshot = root.latestScreenshot
            }
          }
        } catch (e) {}
      }
    }
  }

  Process { id: captureProc; onRunningChanged: if (!running) root.refresh() }
  Process { id: copyPathProc }
  Process { id: copyImageProc }
  Process { id: editProc }
  Process { id: viewProc }
  Process {
    id: deleteProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.refresh()
    }
  }

  // Poll screenshot directory periodically
  Timer {
    id: autoPollTimer
    interval: 8000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // ---------------------------------------------------------------------------
  // 2. Top Bar Widget
  // ---------------------------------------------------------------------------
  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.space(6)

    Text {
      text: "📷"
      color: root.popupOpen ? Color.accent : Qt.darker(root.bar.foreground, 1.1)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.title
      anchors.verticalCenter: parent.verticalCenter
      Behavior on color { ColorAnimation { duration: 200 } }
    }

    Rectangle {
      visible: root.totalCount > 0
      width: Math.max(countText.implicitWidth + Style.space(10), Style.space(20))
      height: Style.space(18)
      radius: Style.space(9)
      color: Style.normalFillFor(root.bar.foreground, Color.accent)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: countText
        anchors.centerIn: parent
        text: String(root.totalCount)
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.caption - 1
        font.bold: true
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        root.triggerCapture("smart")
      } else if (mouse.button === Qt.MiddleButton) {
        root.triggerCapture("fullscreen")
      } else {
        root.popupOpen = !root.popupOpen
        if (root.popupOpen) root.refresh()
      }
    }
    onEntered: {
      if (!root.bar) return
      var tip = "Skärmdumpar (" + root.totalCount + " st)\n"
      if (root.latestScreenshot) {
        tip += "Senaste: " + root.latestScreenshot.filename + " (" + root.latestScreenshot.relative_time + ")\n"
      }
      tip += "Vänsterklick för galleri | Högerklick för snabbtagning"
      root.bar.showTooltip(root, tip.trim())
    }
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  // ---------------------------------------------------------------------------
  // 3. Popup Window (KeyboardPanel)
  // ---------------------------------------------------------------------------
  KeyboardPanel {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(480))
    contentHeight: popup.fittedContentHeight(mainColumn.implicitHeight + Style.space(24))

    Column {
      id: mainColumn
      width: Style.space(480)
      spacing: Style.space(12)

      // =======================================================================
      // A. HEADER ROW
      // =======================================================================
      Item {
        width: parent.width
        height: Style.space(30)

        Row {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(8)

          Text {
            text: "📷"
            font.pixelSize: Style.font.title
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "Skärmdumpar"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        // Quick Capture & Window Action Buttons
        Row {
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(6)

          // Area Selection Button
          Rectangle {
            height: Style.space(28)
            width: areaRow.implicitWidth + Style.space(16)
            radius: Style.space(14)
            color: areaMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

            Row {
              id: areaRow
              anchors.centerIn: parent
              spacing: Style.space(6)
              Text {
                text: "✂️"
                font.pixelSize: Style.font.bodySmall
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: "Område"
                color: areaMouse.containsMouse ? Color.background : root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              id: areaMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.triggerCapture("smart")
            }
          }

          // Fullscreen Button
          Rectangle {
            height: Style.space(28)
            width: fullRow.implicitWidth + Style.space(16)
            radius: Style.space(14)
            color: fullMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

            Row {
              id: fullRow
              anchors.centerIn: parent
              spacing: Style.space(6)
              Text {
                text: "🖥️"
                font.pixelSize: Style.font.bodySmall
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: "Helskärm"
                color: fullMouse.containsMouse ? Color.background : root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              id: fullMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.triggerCapture("fullscreen")
            }
          }

          // Close Button
          Rectangle {
            width: Style.space(28)
            height: Style.space(28)
            radius: Style.space(6)
            color: closeMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.urgent) : "transparent"

            Text {
              anchors.centerIn: parent
              text: "✕"
              color: closeMouse.containsMouse ? Color.urgent : Qt.darker(root.bar.foreground, 1.4)
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            MouseArea {
              id: closeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.popupOpen = false
            }
          }
        }
      }

      // =======================================================================
      // B. TOAST NOTIFICATION BANNER
      // =======================================================================
      Rectangle {
        visible: root.toastMessage !== ""
        width: parent.width
        implicitHeight: toastText.implicitHeight + Style.space(12)
        radius: Style.space(6)
        color: root.toastType === "urgent" ? Style.normalFillFor(Color.urgent, Color.urgent) : Style.normalFillFor(Color.accent, Color.accent)
        border.color: root.toastType === "urgent" ? Color.urgent : Color.accent

        Text {
          id: toastText
          anchors.fill: parent
          anchors.margins: Style.space(8)
          text: root.toastMessage
          color: root.toastType === "urgent" ? Color.urgent : Color.accent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
          font.bold: true
          wrapMode: Text.WordWrap
        }
      }

      // =======================================================================
      // C. TABS ROW (Senaste / Historik)
      // =======================================================================
      Row {
        width: parent.width
        spacing: Style.space(8)

        // Tab: Senaste / Preview
        Rectangle {
          width: (parent.width - Style.space(8)) / 2
          height: Style.space(34)
          radius: Style.space(17)
          color: root.currentTab === "latest" ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)
          border.color: root.currentTab === "latest" ? Color.accent : "transparent"

          Row {
            anchors.centerIn: parent
            spacing: Style.space(8)
            Text {
              text: "🖼️"
              font.pixelSize: Style.font.body
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "Förhandsvisning"
              color: root.currentTab === "latest" ? Color.background : root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentTab = "latest"
          }
        }

        // Tab: Historik
        Rectangle {
          width: (parent.width - Style.space(8)) / 2
          height: Style.space(34)
          radius: Style.space(17)
          color: root.currentTab === "history" ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)
          border.color: root.currentTab === "history" ? Color.accent : "transparent"

          Row {
            anchors.centerIn: parent
            spacing: Style.space(8)
            Text {
              text: "📜"
              font.pixelSize: Style.font.body
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: "Historik (" + root.totalCount + ")"
              color: root.currentTab === "history" ? Color.background : root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentTab = "history"
          }
        }
      }

      // =======================================================================
      // D. TAB 1: PREVIEW & ACTIONS (Senaste skärmdump)
      // =======================================================================
      Column {
        width: parent.width
        spacing: Style.space(10)
        visible: root.currentTab === "latest"

        // 1. Interactive Image Preview Area
        Rectangle {
          width: parent.width
          height: Style.space(250)
          radius: Style.space(8)
          color: Color.background
          border.color: Style.normalFillFor(root.bar.foreground, Color.accent)
          clip: true

          Image {
            id: mainPreviewImg
            anchors.fill: parent
            anchors.margins: Style.space(6)
            source: root.currentScreenshot ? root.currentScreenshot.uri : (root.latestScreenshot ? root.latestScreenshot.uri : "")
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            cache: false
            smooth: true
          }

          // Fallback if no screenshots
          Item {
            anchors.fill: parent
            visible: !root.currentScreenshot && !root.latestScreenshot

            Column {
              anchors.centerIn: parent
              spacing: Style.space(8)
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "📷"
                font.pixelSize: Style.space(40)
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Inga skärmdumpar hittades"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.titleSmall
                font.bold: true
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Klicka på 'Område' eller 'Helskärm' för att ta en ny skärmdump."
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }
          }

          // Click on preview to open in full viewer (imv)
          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var target = root.currentScreenshot || root.latestScreenshot
              if (target) root.viewImage(target.path)
            }
          }
        }

        // 2. Metadata Info Bar
        Rectangle {
          width: parent.width
          implicitHeight: metaCol.implicitHeight + Style.space(14)
          radius: Style.space(6)
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          visible: root.currentScreenshot || root.latestScreenshot

          Column {
            id: metaCol
            anchors.fill: parent
            anchors.margins: Style.space(10)
            spacing: Style.space(6)

            // Filename
            Text {
              text: {
                var s = root.currentScreenshot || root.latestScreenshot
                return s ? s.filename : ""
              }
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              elide: Text.ElideMiddle
              width: parent.width
            }

            // Specs row
            Row {
              spacing: Style.space(14)

              // Dimensions
              Row {
                spacing: Style.space(5)
                Text { text: "📐"; font.pixelSize: Style.font.caption }
                Text {
                  text: {
                    var s = root.currentScreenshot || root.latestScreenshot
                    return s && s.dimensions ? s.dimensions : "Okänd storlek"
                  }
                  color: Color.accent
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              // File size
              Row {
                spacing: Style.space(5)
                Text { text: "💾"; font.pixelSize: Style.font.caption }
                Text {
                  text: {
                    var s = root.currentScreenshot || root.latestScreenshot
                    return s ? s.size_human : ""
                  }
                  color: Qt.darker(root.bar.foreground, 1.2)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }
              }

              // Relative time
              Row {
                spacing: Style.space(5)
                Text { text: "🕒"; font.pixelSize: Style.font.caption }
                Text {
                  text: {
                    var s = root.currentScreenshot || root.latestScreenshot
                    return s ? s.relative_time : ""
                  }
                  color: Qt.darker(root.bar.foreground, 1.2)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                }
              }
            }
          }
        }

        // 3. Delete Confirmation Overlay
        Rectangle {
          visible: root.confirmDelete
          width: parent.width
          implicitHeight: delCol.implicitHeight + Style.space(16)
          radius: Style.space(6)
          color: Style.normalFillFor(Color.urgent, Color.urgent)
          border.color: Color.urgent

          Column {
            id: delCol
            anchors.fill: parent
            anchors.margins: Style.space(10)
            spacing: Style.space(8)

            Text {
              text: "⚠ Vill du verkligen ta bort denna skärmdump?"
              color: Color.urgent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
            }

            Row {
              spacing: Style.space(8)

              Rectangle {
                width: Style.space(110)
                height: Style.space(30)
                radius: Style.space(4)
                color: Color.urgent

                Text {
                  anchors.centerIn: parent
                  text: "Ja, ta bort"
                  color: Color.background
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                  font.bold: true
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.doDelete(root.deleteTargetPath)
                }
              }

              Rectangle {
                width: Style.space(90)
                height: Style.space(30)
                radius: Style.space(4)
                color: Style.normalFillFor(root.bar.foreground, Color.accent)

                Text {
                  anchors.centerIn: parent
                  text: "Avbryt"
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.confirmDelete = false
                }
              }
            }
          }
        }

        // 4. Action Buttons Grid
        Column {
          width: parent.width
          spacing: Style.space(8)
          visible: (root.currentScreenshot || root.latestScreenshot) && !root.confirmDelete

          // Primary Actions: Edit & View Fullscreen
          Row {
            width: parent.width
            spacing: Style.space(8)

            // Redigera (Tensaku / Pinta)
            Rectangle {
              width: (parent.width - Style.space(8)) / 2
              height: Style.space(36)
              radius: Style.space(6)
              color: editBtnMouse.containsMouse ? Qt.darker(Color.accent, 1.2) : Color.accent

              Row {
                anchors.centerIn: parent
                spacing: Style.space(8)
                Text { text: "✏️"; font.pixelSize: Style.font.body; anchors.verticalCenter: parent.verticalCenter }
                Text {
                  text: "Redigera / Rita"
                  color: Color.background
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: editBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var target = root.currentScreenshot || root.latestScreenshot
                  if (target) root.editImage(target.path)
                }
              }
            }

            // Visa Fullskärm (imv)
            Rectangle {
              width: (parent.width - Style.space(8)) / 2
              height: Style.space(36)
              radius: Style.space(6)
              color: viewBtnMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : "transparent"
              border.color: Style.normalFillFor(root.bar.foreground, Color.accent)
              border.width: Style.space(1)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(8)
                Text { text: "👁️"; font.pixelSize: Style.font.body; anchors.verticalCenter: parent.verticalCenter }
                Text {
                  text: "Visa fullstorlek"
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: viewBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var target = root.currentScreenshot || root.latestScreenshot
                  if (target) root.viewImage(target.path)
                }
              }
            }
          }

          // System AI Integration: Copy Path & Copy Image Data
          Row {
            width: parent.width
            spacing: Style.space(8)

            // Kopiera Sökväg (Till Claude, Antigravity, Gemini)
            Rectangle {
              width: (parent.width - Style.space(8)) / 2
              height: Style.space(34)
              radius: Style.space(6)
              color: copyPathMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : Style.normalFillFor(root.bar.foreground, Color.accent)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(8)
                Text { text: "📋"; font.pixelSize: Style.font.bodySmall; anchors.verticalCenter: parent.verticalCenter }
                Text {
                  text: "Kopiera sökväg"
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: copyPathMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var target = root.currentScreenshot || root.latestScreenshot
                  if (target) root.copyPath(target.path)
                }
              }
            }

            // Kopiera Bilddata (Till Urklipp)
            Rectangle {
              width: (parent.width - Style.space(8)) / 2
              height: Style.space(34)
              radius: Style.space(6)
              color: copyImgMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : Style.normalFillFor(root.bar.foreground, Color.accent)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(8)
                Text { text: "🖼️"; font.pixelSize: Style.font.bodySmall; anchors.verticalCenter: parent.verticalCenter }
                Text {
                  text: "Kopiera bild"
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.bodySmall
                  font.bold: true
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              MouseArea {
                id: copyImgMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var target = root.currentScreenshot || root.latestScreenshot
                  if (target) root.copyImage(target.path)
                }
              }
            }
          }

          // Radera knapp
          Rectangle {
            width: parent.width
            height: Style.space(32)
            radius: Style.space(6)
            color: delMouse.containsMouse ? Style.normalFillFor(Color.urgent, Color.urgent) : "transparent"
            border.color: Style.normalFillFor(Color.urgent, Color.urgent)
            border.width: Style.space(1)

            Row {
              anchors.centerIn: parent
              spacing: Style.space(8)
              Text { text: "🗑️"; font.pixelSize: Style.font.bodySmall; anchors.verticalCenter: parent.verticalCenter }
              Text {
                text: "Ta bort denna skärmdump"
                color: Color.urgent
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.bodySmall
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              id: delMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                var target = root.currentScreenshot || root.latestScreenshot
                if (target) root.askDelete(target.path)
              }
            }
          }
        }
      }

      // =======================================================================
      // E. TAB 2: HISTORY GALLERY (Spacious, Legible Cards)
      // =======================================================================
      Column {
        width: parent.width
        spacing: Style.space(8)
        visible: root.currentTab === "history"

        Rectangle {
          width: parent.width
          implicitHeight: Math.min(Style.space(420), historyCol.implicitHeight + Style.space(12))
          radius: Style.space(8)
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          clip: true

          Flickable {
            anchors.fill: parent
            anchors.margins: Style.space(6)
            contentHeight: historyCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
              id: historyCol
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: root.screenshots

                Rectangle {
                  width: historyCol.width
                  implicitHeight: histRow.implicitHeight + Style.space(14)
                  radius: Style.space(6)
                  property bool isSelected: root.currentScreenshot && root.currentScreenshot.path === modelData.path
                  color: isSelected ? Style.normalFillFor(Color.accent, Color.accent) : (histMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : "transparent")
                  border.color: isSelected ? Color.accent : "transparent"
                  border.width: Style.space(1)

                  Row {
                    id: histRow
                    anchors.fill: parent
                    anchors.margins: Style.space(8)
                    spacing: Style.space(12)

                    // 1. Large Thumbnail Box
                    Rectangle {
                      width: Style.space(64)
                      height: Style.space(54)
                      radius: Style.space(4)
                      color: Color.background
                      border.color: Style.normalFillFor(root.bar.foreground, Color.accent)
                      anchors.verticalCenter: parent.verticalCenter
                      clip: true

                      Image {
                        anchors.fill: parent
                        anchors.margins: Style.space(2)
                        source: modelData.uri
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: true
                      }
                    }

                    // 2. Large, Clear Metadata Text
                    Column {
                      width: parent.width - Style.space(220)
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: Style.space(4)

                      // Filename (Big & Bold)
                      Text {
                        text: modelData.filename
                        color: root.bar.foreground
                        font.family: root.bar.fontFamily
                        font.pixelSize: Style.font.bodySmall
                        font.bold: true
                        elide: Text.ElideMiddle
                        width: parent.width
                      }

                      // Specs Row (Dimensions & File Size)
                      Row {
                        spacing: Style.space(6)
                        Text {
                          text: modelData.dimensions || ""
                          color: Color.accent
                          font.family: root.bar.fontFamily
                          font.pixelSize: Style.font.caption
                          font.bold: true
                        }
                        Text {
                          text: "•"
                          color: Qt.darker(root.bar.foreground, 1.5)
                          font.pixelSize: Style.font.caption
                        }
                        Text {
                          text: modelData.size_human
                          color: Qt.darker(root.bar.foreground, 1.2)
                          font.family: root.bar.fontFamily
                          font.pixelSize: Style.font.caption
                          font.bold: true
                        }
                      }

                      // Timestamp
                      Row {
                        spacing: Style.space(4)
                        Text { text: "🕒"; font.pixelSize: Style.font.caption - 2 }
                        Text {
                          text: modelData.relative_time
                          color: Qt.darker(root.bar.foreground, 1.3)
                          font.family: root.bar.fontFamily
                          font.pixelSize: Style.font.caption
                        }
                      }
                    }

                    // 3. Large, Easy-to-Click Action Buttons on the right
                    Row {
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: Style.space(6)

                      // Edit Button
                      Rectangle {
                        width: Style.space(32)
                        height: Style.space(32)
                        radius: Style.space(4)
                        color: hEditMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

                        Text {
                          anchors.centerIn: parent
                          text: "✏️"
                          font.pixelSize: Style.font.bodySmall
                        }

                        MouseArea {
                          id: hEditMouse
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.editImage(modelData.path)
                        }
                      }

                      // Copy Path Button
                      Rectangle {
                        width: Style.space(32)
                        height: Style.space(32)
                        radius: Style.space(4)
                        color: hCopyMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

                        Text {
                          anchors.centerIn: parent
                          text: "📋"
                          font.pixelSize: Style.font.bodySmall
                        }

                        MouseArea {
                          id: hCopyMouse
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.copyPath(modelData.path)
                        }
                      }

                      // View Button
                      Rectangle {
                        width: Style.space(32)
                        height: Style.space(32)
                        radius: Style.space(4)
                        color: hViewMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

                        Text {
                          anchors.centerIn: parent
                          text: "👁️"
                          font.pixelSize: Style.font.bodySmall
                        }

                        MouseArea {
                          id: hViewMouse
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.viewImage(modelData.path)
                        }
                      }

                      // Delete Button
                      Rectangle {
                        width: Style.space(32)
                        height: Style.space(32)
                        radius: Style.space(4)
                        color: hDelMouse.containsMouse ? Color.urgent : Style.normalFillFor(root.bar.foreground, Color.urgent)

                        Text {
                          anchors.centerIn: parent
                          text: "🗑️"
                          font.pixelSize: Style.font.bodySmall
                        }

                        MouseArea {
                          id: hDelMouse
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root.askDelete(modelData.path)
                        }
                      }
                    }
                  }

                  // Row click switches to preview
                  MouseArea {
                    id: histMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                      root.currentScreenshot = modelData
                      root.currentTab = "latest"
                    }
                  }
                }
              }

              // Empty State
              Item {
                width: parent.width
                height: Style.space(120)
                visible: !root.screenshots || root.screenshots.length === 0

                Column {
                  anchors.centerIn: parent
                  spacing: Style.space(8)
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "📷"
                    font.pixelSize: Style.font.display
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Ingen historik än"
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: true
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
