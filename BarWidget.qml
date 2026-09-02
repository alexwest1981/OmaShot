import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "./I18n.js" as I18n

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
  property string deleteTargetName: ""

  readonly property string systemLang: Quickshell.env("LANG") || Qt.locale().name

  function tr(key, params) {
    return I18n.t(key, params, root.systemLang, Qt.locale().name)
  }

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
    captureProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--capture", mode || "smart", "--lang", root.systemLang]
    captureProc.running = true
  }

  function copyPath(fpath) {
    if (!fpath) return
    copyPathProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--copy-path", fpath]
    copyPathProc.running = true
    showToast(root.tr("toast_path_copied"), "success")
  }

  function copyImage(fpath) {
    if (!fpath) return
    copyImageProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--copy-image", fpath]
    copyImageProc.running = true
    showToast(root.tr("toast_image_copied"), "success")
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

  function askDelete(fpath, fname) {
    if (!fpath) return
    deleteTargetPath = fpath
    deleteTargetName = fname || fpath.split("/").pop()
    confirmDelete = true
  }

  function doDelete(fpath) {
    confirmDelete = false
    if (!fpath) return
    var target = fpath
    deleteTargetPath = ""
    deleteTargetName = ""
    if (root.currentScreenshot && root.currentScreenshot.path === target) {
      root.currentScreenshot = null
    }
    deleteProc.command = ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--delete", target, "--lang", root.systemLang]
    deleteProc.running = true
    showToast(root.tr("toast_deleted"), "urgent")
  }

  implicitWidth: contentRow.implicitWidth + Style.space(16)
  implicitHeight: barSize

  // ---------------------------------------------------------------------------
  // 1. Process Handlers
  // ---------------------------------------------------------------------------
  Process {
    id: listProc
    command: ["python3", Quickshell.env("HOME") + "/.config/omarchy/plugins/custom.screenshots/screenshot_manager.py", "--list", "--lang", root.systemLang]
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
      onStreamFinished: {
        root.refresh()
      }
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
      var fname = root.latestScreenshot ? root.latestScreenshot.filename : ""
      var ftime = root.latestScreenshot ? root.latestScreenshot.relative_time : ""
      var tip = root.tr("tooltip_title", {
        count: root.totalCount,
        filename: fname,
        time: ftime
      })
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
    contentWidth: popup.fittedContentWidth(Style.space(560))
    contentHeight: popup.fittedContentHeight(mainColumn.implicitHeight + Style.space(28))

    Column {
      id: mainColumn
      width: Style.space(560)
      spacing: Style.space(10)

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
            text: root.tr("title")
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
            height: Style.space(26)
            width: areaRow.implicitWidth + Style.space(14)
            radius: Style.space(13)
            color: areaMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

            Row {
              id: areaRow
              anchors.centerIn: parent
              spacing: Style.space(5)
              Text {
                text: "✂️"
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: root.tr("region")
                color: areaMouse.containsMouse ? Color.background : root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
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
            height: Style.space(26)
            width: fullRow.implicitWidth + Style.space(14)
            radius: Style.space(13)
            color: fullMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

            Row {
              id: fullRow
              anchors.centerIn: parent
              spacing: Style.space(5)
              Text {
                text: "🖥️"
                font.pixelSize: Style.font.caption
                anchors.verticalCenter: parent.verticalCenter
              }
              Text {
                text: root.tr("fullscreen")
                color: fullMouse.containsMouse ? Color.background : root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
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
            width: Style.space(26)
            height: Style.space(26)
            radius: Style.space(5)
            color: closeMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.urgent) : "transparent"

            Text {
              anchors.centerIn: parent
              text: "✕"
              color: closeMouse.containsMouse ? Color.urgent : Qt.darker(root.bar.foreground, 1.4)
              font.pixelSize: Style.font.caption
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
      // B. GLOBAL DELETE CONFIRMATION OVERLAY
      // =======================================================================
      Rectangle {
        visible: root.confirmDelete
        width: parent.width
        implicitHeight: delCol.implicitHeight + Style.space(14)
        radius: Style.space(6)
        color: Style.normalFillFor(Color.urgent, Color.urgent)
        border.color: Color.urgent

        Column {
          id: delCol
          anchors.fill: parent
          anchors.margins: Style.space(8)
          spacing: Style.space(6)

          Text {
            text: "⚠ " + root.tr("delete_confirm_title", { name: root.deleteTargetName })
            color: Color.urgent
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            wrapMode: Text.WordWrap
            width: parent.width
          }

          Row {
            spacing: Style.space(8)

            Rectangle {
              width: Style.space(100)
              height: Style.space(26)
              radius: Style.space(4)
              color: Color.urgent

              Text {
                anchors.centerIn: parent
                text: root.tr("delete_confirm_yes")
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
              width: Style.space(80)
              height: Style.space(26)
              radius: Style.space(4)
              color: Style.normalFillFor(root.bar.foreground, Color.accent)

              Text {
                anchors.centerIn: parent
                text: root.tr("delete_confirm_cancel")
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
              }

              MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  root.confirmDelete = false
                  root.deleteTargetPath = ""
                }
              }
            }
          }
        }
      }

      // =======================================================================
      // C. TOAST NOTIFICATION BANNER
      // =======================================================================
      Rectangle {
        visible: root.toastMessage !== "" && !root.confirmDelete
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
          font.pixelSize: Style.font.caption
          font.bold: true
          wrapMode: Text.WordWrap
        }
      }

      // =======================================================================
      // D. TABS ROW (Preview / History)
      // =======================================================================
      Row {
        width: parent.width
        spacing: Style.space(8)

        // Tab: Preview
        Rectangle {
          width: (parent.width - Style.space(8)) / 2
          height: Style.space(32)
          radius: Style.space(16)
          color: root.currentTab === "latest" ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)
          border.color: root.currentTab === "latest" ? Color.accent : "transparent"

          Row {
            anchors.centerIn: parent
            spacing: Style.space(6)
            Text {
              text: "🖼️"
              font.pixelSize: Style.font.bodySmall
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: root.tr("preview")
              color: root.currentTab === "latest" ? Color.background : root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: root.currentTab === "latest"
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

        // Tab: History
        Rectangle {
          width: (parent.width - Style.space(8)) / 2
          height: Style.space(32)
          radius: Style.space(16)
          color: root.currentTab === "history" ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)
          border.color: root.currentTab === "history" ? Color.accent : "transparent"

          Row {
            anchors.centerIn: parent
            spacing: Style.space(6)
            Text {
              text: "📜"
              font.pixelSize: Style.font.bodySmall
              anchors.verticalCenter: parent.verticalCenter
            }
            Text {
              text: root.tr("history_with_count", { count: root.totalCount })
              color: root.currentTab === "history" ? Color.background : root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: root.currentTab === "history"
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
      // E. TAB 1: PREVIEW & ACTIONS (Larger Image Preview & Clean Buttons)
      // =======================================================================
      Column {
        width: parent.width
        spacing: Style.space(8)
        visible: root.currentTab === "latest"

        // 1. Interactive Image Preview Area (Generous size & strictly centered inside dark box)
        Rectangle {
          width: parent.width
          height: Style.space(265)
          radius: Style.space(8)
          color: "#0c0d14"
          border.color: Style.normalFillFor(root.bar.foreground, Color.accent)
          clip: true

          Item {
            anchors.fill: parent
            anchors.margins: Style.space(6)
            clip: true

            Image {
              id: mainPreviewImg
              anchors.centerIn: parent
              width: parent.width
              height: parent.height
              source: root.currentScreenshot ? root.currentScreenshot.uri : (root.latestScreenshot ? root.latestScreenshot.uri : "")
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              cache: false
              smooth: true
              mipmap: true
            }
          }

          // Fallback if no screenshots
          Item {
            anchors.fill: parent
            visible: !root.currentScreenshot && !root.latestScreenshot

            Column {
              anchors.centerIn: parent
              spacing: Style.space(6)
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "📷"
                font.pixelSize: Style.space(36)
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.tr("empty_preview_title")
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.tr("empty_preview_sub")
                color: Qt.darker(root.bar.foreground, 1.4)
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
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
          implicitHeight: metaCol.implicitHeight + Style.space(12)
          radius: Style.space(6)
          color: Style.normalFillFor(root.bar.foreground, Color.accent)
          visible: root.currentScreenshot || root.latestScreenshot

          Column {
            id: metaCol
            anchors.fill: parent
            anchors.margins: Style.space(8)
            spacing: Style.space(4)

            // Filename
            Text {
              text: {
                var s = root.currentScreenshot || root.latestScreenshot
                return s ? s.filename : ""
              }
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.bodySmall
              font.bold: true
              elide: Text.ElideMiddle
              width: parent.width
            }

            // Specs row
            Row {
              spacing: Style.space(12)

              // Dimensions
              Row {
                spacing: Style.space(4)
                Text { text: "📐"; font.pixelSize: Style.font.caption - 1 }
                Text {
                  text: {
                    var s = root.currentScreenshot || root.latestScreenshot
                    return s && s.dimensions ? s.dimensions : root.tr("unknown_size")
                  }
                  color: Color.accent
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption - 1
                  font.bold: true
                }
              }

              // File size
              Row {
                spacing: Style.space(4)
                Text { text: "💾"; font.pixelSize: Style.font.caption - 1 }
                Text {
                  text: {
                    var s = root.currentScreenshot || root.latestScreenshot
                    return s ? s.size_human : ""
                  }
                  color: Qt.darker(root.bar.foreground, 1.2)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption - 1
                  font.bold: true
                }
              }

              // Relative time
              Row {
                spacing: Style.space(4)
                Text { text: "🕒"; font.pixelSize: Style.font.caption - 1 }
                Text {
                  text: {
                    var s = root.currentScreenshot || root.latestScreenshot
                    return s ? s.relative_time : ""
                  }
                  color: Qt.darker(root.bar.foreground, 1.2)
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption - 1
                }
              }
            }
          }
        }

        // 3. Action Buttons Grid
        Column {
          width: parent.width
          spacing: Style.space(6)
          visible: (root.currentScreenshot || root.latestScreenshot) && !root.confirmDelete

          // Primary Actions: Edit & View Fullscreen
          Row {
            width: parent.width
            spacing: Style.space(6)

            // Edit (Tensaku / Pinta)
            Rectangle {
              width: (parent.width - Style.space(6)) / 2
              height: Style.space(32)
              radius: Style.space(5)
              color: editBtnMouse.containsMouse ? Qt.darker(Color.accent, 1.2) : Color.accent

              Row {
                anchors.centerIn: parent
                spacing: Style.space(6)
                Text { text: "✏️"; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }
                Text {
                  text: root.tr("edit")
                  color: Color.background
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
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

            // View Fullscreen (imv)
            Rectangle {
              width: (parent.width - Style.space(6)) / 2
              height: Style.space(32)
              radius: Style.space(5)
              color: viewBtnMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : "transparent"
              border.color: Style.normalFillFor(root.bar.foreground, Color.accent)
              border.width: Style.space(1)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(6)
                Text { text: "👁️"; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }
                Text {
                  text: root.tr("view_full")
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
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
            spacing: Style.space(6)

            // Copy Path
            Rectangle {
              width: (parent.width - Style.space(6)) / 2
              height: Style.space(30)
              radius: Style.space(5)
              color: copyPathMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : Style.normalFillFor(root.bar.foreground, Color.accent)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(6)
                Text { text: "📋"; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }
                Text {
                  text: root.tr("copy_path")
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
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

            // Copy Image
            Rectangle {
              width: (parent.width - Style.space(6)) / 2
              height: Style.space(30)
              radius: Style.space(5)
              color: copyImgMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : Style.normalFillFor(root.bar.foreground, Color.accent)

              Row {
                anchors.centerIn: parent
                spacing: Style.space(6)
                Text { text: "🖼️"; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }
                Text {
                  text: root.tr("copy_image")
                  color: root.bar.foreground
                  font.family: root.bar.fontFamily
                  font.pixelSize: Style.font.caption
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

          // Delete button
          Rectangle {
            width: parent.width
            height: Style.space(28)
            radius: Style.space(5)
            color: delMouse.containsMouse ? Style.normalFillFor(Color.urgent, Color.urgent) : "transparent"
            border.color: Style.normalFillFor(Color.urgent, Color.urgent)
            border.width: Style.space(1)

            Row {
              anchors.centerIn: parent
              spacing: Style.space(6)
              Text { text: "🗑️"; font.pixelSize: Style.font.caption; anchors.verticalCenter: parent.verticalCenter }
              Text {
                text: root.tr("delete_btn")
                color: Color.urgent
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
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
                if (target) root.askDelete(target.path, target.filename)
              }
            }
          }
        }
      }

      // =======================================================================
      // F. TAB 2: HISTORY GALLERY
      // =======================================================================
      Column {
        width: parent.width
        spacing: Style.space(8)
        visible: root.currentTab === "history"

        Rectangle {
          width: parent.width
          height: Style.space(420)
          radius: Style.space(8)
          color: Color.background
          border.color: Style.normalFillFor(root.bar.foreground, Color.accent)
          clip: true

          ListView {
            id: histListView
            anchors.fill: parent
            anchors.margins: Style.space(6)
            spacing: Style.space(6)
            model: root.screenshots
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
              width: histListView.width
              height: Style.space(64)

              Rectangle {
                anchors.fill: parent
                radius: Style.space(6)
                property bool isSelected: root.currentScreenshot && root.currentScreenshot.path === modelData.path
                color: isSelected ? Style.normalFillFor(Color.accent, Color.accent) : (cardMouse.containsMouse ? Style.normalFillFor(root.bar.foreground, Color.accent) : Style.normalFillFor(root.bar.foreground, root.bar.foreground))
                border.color: isSelected ? Color.accent : "transparent"
                border.width: Style.space(1)

                // Left Section: Thumbnail & Metadata Text
                Row {
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(8)
                  anchors.right: actionsRow.left
                  anchors.rightMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(10)

                  // Thumbnail
                  Rectangle {
                    width: Style.space(56)
                    height: Style.space(46)
                    radius: Style.space(4)
                    color: "#111"
                    border.color: Style.normalFillFor(root.bar.foreground, Color.accent)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Image {
                      anchors.fill: parent
                      anchors.margins: Style.space(2)
                      source: modelData.uri
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                      cache: true
                    }
                  }

                  // Metadata Column
                  Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Style.space(66)
                    spacing: Style.space(2)

                    // Filename
                    Text {
                      text: modelData.filename
                      color: root.bar.foreground
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.caption
                      font.bold: true
                      elide: Text.ElideMiddle
                      width: parent.width
                    }

                    // Specs Row (Dimensions & Size)
                    Row {
                      spacing: Style.space(6)
                      Text {
                        text: modelData.dimensions || ""
                        color: Color.accent
                        font.family: root.bar.fontFamily
                        font.pixelSize: Style.font.caption - 1
                        font.bold: true
                      }
                      Text {
                        text: "•"
                        color: Qt.darker(root.bar.foreground, 1.5)
                        font.pixelSize: Style.font.caption - 1
                      }
                      Text {
                        text: modelData.size_human
                        color: Qt.darker(root.bar.foreground, 1.2)
                        font.family: root.bar.fontFamily
                        font.pixelSize: Style.font.caption - 1
                      }
                    }

                    // Date
                    Text {
                      text: modelData.relative_time
                      color: Qt.darker(root.bar.foreground, 1.4)
                      font.family: root.bar.fontFamily
                      font.pixelSize: Style.font.caption - 2
                    }
                  }
                }

                // Clickable area covering thumbnail & text to select
                MouseArea {
                  id: cardMouse
                  anchors.left: parent.left
                  anchors.top: parent.top
                  anchors.bottom: parent.bottom
                  anchors.right: actionsRow.left
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.currentScreenshot = modelData
                    root.currentTab = "latest"
                  }
                }

                // Right Section: Quick Action Buttons
                Row {
                  id: actionsRow
                  anchors.right: parent.right
                  anchors.rightMargin: Style.space(8)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(4)
                  z: 10

                  // Edit Button
                  Rectangle {
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: Style.space(4)
                    color: hEditMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      text: "✏️"
                      font.pixelSize: Style.font.caption
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
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: Style.space(4)
                    color: hCopyMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      text: "📋"
                      font.pixelSize: Style.font.caption
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
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: Style.space(4)
                    color: hViewMouse.containsMouse ? Color.accent : Style.normalFillFor(root.bar.foreground, Color.accent)

                    Text {
                      anchors.centerIn: parent
                      text: "👁️"
                      font.pixelSize: Style.font.caption
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
                    width: Style.space(28)
                    height: Style.space(28)
                    radius: Style.space(4)
                    color: hDelMouse.containsMouse ? Color.urgent : Style.normalFillFor(root.bar.foreground, Color.urgent)

                    Text {
                      anchors.centerIn: parent
                      text: "🗑️"
                      font.pixelSize: Style.font.caption
                    }

                    MouseArea {
                      id: hDelMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: root.askDelete(modelData.path, modelData.filename)
                    }
                  }
                }
              }
            }
          }

          // Empty State
          Item {
            anchors.fill: parent
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
                text: root.tr("empty_history_title")
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
