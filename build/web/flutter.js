document.addEventListener('DOMContentLoaded', function() {
    // Menghapus 'user-select: none;' dari <flt-glass-pane>
    let glassPane = document.querySelector('flt-glass-pane');
    if (glassPane) {
        glassPane.style.userSelect = 'auto !important';
    }

    // Menghapus 'pointer-events: none;' dari <flt-scene-host> jika ada dalam shadow DOM
    let sceneHost = document.querySelector('flt-scene-host');
    if (sceneHost && sceneHost.shadowRoot) {
        let shadowRoot = sceneHost.shadowRoot;
        let scene = shadowRoot.querySelector('flt-scene');
        if (scene) {
            scene.style.pointerEvents = 'auto !important';
        }
    }

    let bodyElement = document.querySelector('body');
    if (bodyElement) {
        bodyElement.style = "";
    }
  });