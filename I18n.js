// OmaShot i18n Localization Engine
// Automatically detects system locale (sv, en, de, fr, es, no, da, fi) with fallback to English.

.pragma library

var currentLocale = "auto"

var translations = {
  "en": {
    "title": "Screenshots",
    "region": "Region",
    "fullscreen": "Fullscreen",
    "preview": "Preview",
    "history": "History",
    "history_with_count": "History ({count})",
    "edit": "Edit / Annotate",
    "view_full": "View Fullscreen",
    "copy_path": "Copy Path",
    "copy_image": "Copy Image",
    "delete_btn": "Delete this screenshot",
    "delete_confirm_title": "Are you sure you want to delete screenshot: {name}?",
    "delete_confirm_yes": "Yes, delete",
    "delete_confirm_cancel": "Cancel",
    "toast_path_copied": "📋 Filepath copied! Paste directly into AI/Claude/Gemini.",
    "toast_image_copied": "🖼️ Image copied to clipboard!",
    "toast_deleted": "🗑️ Screenshot was deleted.",
    "empty_preview_title": "No screenshots found",
    "empty_preview_sub": "Click 'Region' or 'Fullscreen' to capture a new screenshot.",
    "empty_history_title": "No history yet",
    "unknown_size": "Unknown size",
    "tooltip_title": "Screenshots ({count})\nLatest: {filename} ({time})\nLeft-click: Gallery | Right-click: Region capture",
    "just_now": "Just now",
    "mins_ago": "{mins}m ago",
    "today": "Today",
    "yesterday": "Yesterday"
  },
  "sv": {
    "title": "Skärmdumpar",
    "region": "Område",
    "fullscreen": "Helskärm",
    "preview": "Förhandsvisning",
    "history": "Historik",
    "history_with_count": "Historik ({count})",
    "edit": "Redigera / Rita",
    "view_full": "Visa fullstorlek",
    "copy_path": "Kopiera sökväg",
    "copy_image": "Kopiera bild",
    "delete_btn": "Ta bort denna skärmdump",
    "delete_confirm_title": "Vill du ta bort skärmdumpen: {name}?",
    "delete_confirm_yes": "Ja, ta bort",
    "delete_confirm_cancel": "Avbryt",
    "toast_path_copied": "📋 Sökvägen kopierad! Klistra in direkt till AI/Claude/Gemini.",
    "toast_image_copied": "🖼️ Bilddata kopierad till urklipp!",
    "toast_deleted": "🗑️ Skärmdumpen raderades.",
    "empty_preview_title": "Inga skärmdumpar hittades",
    "empty_preview_sub": "Klicka på 'Område' eller 'Helskärm' för att ta en ny skärmdump.",
    "empty_history_title": "Ingen historik än",
    "unknown_size": "Okänd storlek",
    "tooltip_title": "Skärmdumpar ({count} st)\nSenaste: {filename} ({time})\nVänsterklick för galleri | Högerklick för snabbtagning",
    "just_now": "Nyss",
    "mins_ago": "{mins} min sedan",
    "today": "Idag",
    "yesterday": "Igår"
  },
  "de": {
    "title": "Bildschirmfotos",
    "region": "Bereich",
    "fullscreen": "Vollbild",
    "preview": "Vorschau",
    "history": "Verlauf",
    "history_with_count": "Verlauf ({count})",
    "edit": "Bearbeiten / Zeichnen",
    "view_full": "Vollansicht",
    "copy_path": "Pfad kopieren",
    "copy_image": "Bild kopieren",
    "delete_btn": "Dieses Bildschirmfoto löschen",
    "delete_confirm_title": "Bildschirmfoto wirklich löschen: {name}?",
    "delete_confirm_yes": "Ja, löschen",
    "delete_confirm_cancel": "Abbrechen",
    "toast_path_copied": "📋 Dateipfad kopiert! Direkt in KI/Claude/Gemini einfügen.",
    "toast_image_copied": "🖼️ Bild in die Zwischenablage kopiert!",
    "toast_deleted": "🗑️ Bildschirmfoto wurde gelöscht.",
    "empty_preview_title": "Keine Bildschirmfotos gefunden",
    "empty_preview_sub": "Klicke auf 'Bereich' oder 'Vollbild', um eins aufzunehmen.",
    "empty_history_title": "Noch kein Verlauf vorhanden",
    "unknown_size": "Unbekannte Größe",
    "tooltip_title": "Bildschirmfotos ({count})\nNeuestes: {filename} ({time})",
    "just_now": "Gerade eben",
    "mins_ago": "vor {mins} Min.",
    "today": "Heute",
    "yesterday": "Gestern"
  },
  "no": {
    "title": "Skjermbilder",
    "region": "Område",
    "fullscreen": "Fullskjerm",
    "preview": "Forhåndsvisning",
    "history": "Historikk",
    "history_with_count": "Historikk ({count})",
    "edit": "Rediger / Tegn",
    "view_full": "Full størrelse",
    "copy_path": "Kopier bane",
    "copy_image": "Kopier bilde",
    "delete_btn": "Slett dette skjermbildet",
    "delete_confirm_title": "Vil du slette skjermbildet: {name}?",
    "delete_confirm_yes": "Ja, slett",
    "delete_confirm_cancel": "Avbryt",
    "toast_path_copied": "📋 Filbane kopiert! Lim inn direkte i AI/Claude/Gemini.",
    "toast_image_copied": "🖼️ Bilde kopiert til utklippstavlen!",
    "toast_deleted": "🗑️ Skjermbildet ble slettet.",
    "empty_preview_title": "Ingen skjermbilder funnet",
    "empty_preview_sub": "Klikk 'Område' eller 'Fullskjerm' for å ta et nytt skjermbilde.",
    "empty_history_title": "Ingen historikk ennå",
    "unknown_size": "Ukjent størrelse",
    "tooltip_title": "Skjermbilder ({count})\nSiste: {filename} ({time})",
    "just_now": "Nå",
    "mins_ago": "{mins} min siden",
    "today": "I dag",
    "yesterday": "I går"
  },
  "da": {
    "title": "Skærmbilleder",
    "region": "Område",
    "fullscreen": "Fuldskærm",
    "preview": "Forhåndsvisning",
    "history": "Historik",
    "history_with_count": "Historik ({count})",
    "edit": "Rediger / Tegn",
    "view_full": "Fuld størrelse",
    "copy_path": "Kopier sti",
    "copy_image": "Kopier billede",
    "delete_btn": "Slet dette skærmbillede",
    "delete_confirm_title": "Vil du slette skærmbilledet: {name}?",
    "delete_confirm_yes": "Ja, slet",
    "delete_confirm_cancel": "Annuller",
    "toast_path_copied": "📋 Filsti kopieret! Indsæt direkte i AI/Claude/Gemini.",
    "toast_image_copied": "🖼️ Billede kopieret til udklipsholder!",
    "toast_deleted": "🗑️ Skærmbilledet blev slettet.",
    "empty_preview_title": "Ingen skærmbilleder fundet",
    "empty_preview_sub": "Klik 'Område' eller 'Fuldskærm' for at tage et nyt skærmbillede.",
    "empty_history_title": "Ingen historik endnu",
    "unknown_size": "Ukendt størrelse",
    "tooltip_title": "Skærmbilleder ({count})\nSeneste: {filename} ({time})",
    "just_now": "Lige nu",
    "mins_ago": "{mins} min siden",
    "today": "I dag",
    "yesterday": "I går"
  }
}

function getActiveLanguage(envLang, qmlLocale) {
  if (currentLocale !== "auto" && translations[currentLocale]) {
    return currentLocale
  }
  
  var raw = String(envLang || qmlLocale || "").toLowerCase()
  if (raw.indexOf("sv") === 0) return "sv"
  if (raw.indexOf("de") === 0) return "de"
  if (raw.indexOf("no") === 0 || raw.indexOf("nb") === 0 || raw.indexOf("nn") === 0) return "no"
  if (raw.indexOf("da") === 0) return "da"
  if (raw.indexOf("en") === 0) return "en"
  return "en" // Default fallback
}

function t(key, params, envLang, qmlLocale) {
  var lang = getActiveLanguage(envLang, qmlLocale)
  var dict = translations[lang] || translations["en"]
  var str = dict[key] || translations["en"][key] || key
  
  if (params && typeof params === "object") {
    for (var p in params) {
      str = str.replace(new RegExp("\\{" + p + "\\}", "g"), String(params[p]))
    }
  }
  return str
}
