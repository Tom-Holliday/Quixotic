// Abort if site flag disables it
if (document.documentElement.dataset.webgl === 'off') { /* no-op */ }

// three-hero.js
import * as THREE from "https://unpkg.com/three@0.160.0/build/three.module.js";

// Respect reduced motion
if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
  // Do nothing—fallback is your static hero
} else {
  const container = document.querySelector('[data-webgl="hero"]');
  if (container) {
    let w = container.clientWidth || container.offsetWidth || 1280;
    let h = container.clientHeight || 360;

    const scene   = new THREE.Scene();
    const camera  = new THREE.PerspectiveCamera(55, w / h, 0.1, 100);
    camera.position.set(0, 2.1, 6);

    const renderer = new THREE.WebGLRenderer({
      antialias: false,
      alpha: true,
      powerPreference: "low-power",
    });
    renderer.setClearColor(0x000000, 0); 
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.75));
    renderer.setSize(w, h);
    container.appendChild(renderer.domElement);

    // Subtle wireframe wave plane
    const W = 12, H = 6, XS = 64, YS = 32;
    const geometry = new THREE.PlaneGeometry(W, H, XS, YS);
    const material = new THREE.MeshStandardMaterial({
      color: 0x1d4ed8,         // brand blue
      roughness: 0.85,
      metalness: 0.05,
      wireframe: true,
      transparent: true,
      opacity: 0.18,
    });
    const mesh = new THREE.Mesh(geometry, material);
    mesh.rotation.x = -Math.PI * 0.47;
    mesh.position.y = -1.0;
    scene.add(mesh);

    // Soft lighting
    scene.fog = new THREE.Fog(0x0b1220, 8, 30);
    scene.add(new THREE.AmbientLight(0x92b4ff, 0.6));
    const dir = new THREE.DirectionalLight(0xffffff, 0.65);
    dir.position.set(2, 3, 1);
    scene.add(dir);

    // Animate vertices
    let raf = null, t = 0;
    const px = geometry.parameters.widthSegments + 1;
    const pz = geometry.parameters.heightSegments + 1;
    const pos = geometry.attributes.position;

    function animate() {
      t += 0.008;
      for (let i = 0; i < pos.count; i++) {
        const ix = i % px;
        const iz = (i / px) | 0;
        const x = ix / (px - 1);
        const z = iz / (pz - 1);
        const y =
          Math.sin((x + t) * 3.1) * 0.15 +
          Math.cos((z + t) * 4.0) * 0.12;
        pos.setZ(i, y);
      }
      pos.needsUpdate = true;
      renderer.render(scene, camera);
      raf = requestAnimationFrame(animate);
    }

    // Only render when visible
    const io = new IntersectionObserver((entries) => {
      const e = entries[0];
      if (e && e.isIntersecting) {
        if (!raf) animate();
      } else if (raf) {
        cancelAnimationFrame(raf);
        raf = null;
      }
    }, { threshold: 0.05 });
    io.observe(container);

    // Resize
    function onResize() {
      w = container.clientWidth;
      h = container.clientHeight || (container.parentElement?.clientHeight ?? h);
      camera.aspect = Math.max(1, w / Math.max(1, h));
      camera.updateProjectionMatrix();
      renderer.setSize(w, h);
    }
    window.addEventListener("resize", onResize);
  }
}
