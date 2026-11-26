// No page is cached: a cached page goes stale at the next deploy (it points to CSS/JS
// digests that no longer exist, so it renders half broken) and admin pages carry members'
// personal data that must not stay in the browser. Offline, navigations get the small
// self-contained page below instead. Bumping CACHE_NAME makes "activate" delete the page
// copies left by earlier versions on every device.
const CACHE_NAME = "circographe-v2"

const OFFLINE_HTML = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Hors ligne · Le Circographe</title>
<style>
  body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #f6f4ef;
         font-family: system-ui, -apple-system, "Segoe UI", sans-serif; color: #1f2937; }
  main { max-width: 26rem; padding: 2rem; text-align: center; }
  h1 { font-size: 1.4rem; margin: 0 0 .75rem; color: #1F5C55; }
  p { line-height: 1.5; margin: 0 0 1.5rem; }
  button { font: inherit; font-weight: 600; color: #fff; background: #1F5C55; border: 0;
           border-radius: 999px; padding: .75rem 1.5rem; min-height: 44px; cursor: pointer; }
</style>
</head>
<body>
<main>
  <h1>Vous êtes hors ligne</h1>
  <p>Le Circographe n'est pas joignable pour le moment. Vérifiez votre connexion, puis réessayez.</p>
  <button type="button" onclick="location.reload()">Réessayer</button>
</main>
</body>
</html>`

// Install: skip waiting to activate immediately
self.addEventListener("install", () => {
  self.skipWaiting()
})

// Activate: delete every earlier cache (page copies of v1), then control open pages
self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys()
      .then((names) =>
        Promise.all(
          names
            .filter((n) => n.startsWith("circographe-") && n !== CACHE_NAME)
            .map((n) => caches.delete(n))
        )
      )
      .then(() => self.clients.claim())
  )
})

// Fetch: page navigations always go to the network; offline, the page above.
// Everything else (assets, Turbo fetches) is left to the browser and its HTTP cache.
// A fetch handler is also what Chrome needs to offer installing the app.
self.addEventListener("fetch", (event) => {
  if (event.request.mode !== "navigate") return

  event.respondWith(
    fetch(event.request).catch(() =>
      new Response(OFFLINE_HTML, {
        status: 503,
        headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" }
      })
    )
  )
})

// Push notifications
self.addEventListener("push", async (event) => {
  const { title, options } = await event.data.json()
  event.waitUntil(self.registration.showNotification(title, options))
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      for (const client of clientList) {
        if (new URL(client.url).pathname === event.notification.data.path && "focus" in client) {
          return client.focus()
        }
      }
      if (clients.openWindow) {
        return clients.openWindow(event.notification.data.path)
      }
    })
  )
})
