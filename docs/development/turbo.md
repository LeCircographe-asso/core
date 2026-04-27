# ⚡ Turbo Guide

> **Statut** : stable
> **Public cible** : contributeur
> **Dernière vérification** : 2026-04-27
> **Sources de vérité** : `app/javascript/controllers/`, `config/importmap.rb`, vues `app/views/**/*.html.erb`.

This guide explains how Turbo works inside Le Circographe, how it collaborates with Stimulus and Importmap, and the diagnostic routines you can apply when something fails (e.g. Firefox showing an infinite loading bar).

## 1. Turbo in Le Circographe

- `app/views/home/index.html.erb` streams upcoming events through a `<turbo-frame id="events_upcoming">` fed by `EventsController#upcoming`.
- Admin dashboards rely on Turbo Frames to refresh tables and forms without full page reloads.
- Stimulus controllers (e.g. `app/javascript/controllers/slider_controller.js`) enhance Turbo-delivered HTML with progressive enhancement only after the frame connects.

> Always keep controllers skinny: Turbo responses should render view logic or call service objects; business logic stays in models/services.

## 2. Turbo building blocks

| Piece | Purpose | Typical usage in the app |
| --- | --- | --- |
| Turbo Drive | Intercepts navigation, keeps layout persistent, streams HTML faster | All routes by default |
| Turbo Frames | Replace only their DOM subtree when the server responds with a matching frame | `events_upcoming`, admin list panels |
| Turbo Streams | Push DOM changes over HTTP or Solid Cable (`turbo_stream.replace`, `append`, `remove`) | Admin create/update flows |
| Stimulus | Attaches JavaScript behaviour to Turbo-rendered HTML | Sliders, animations, form helpers |
| Importmap | Resolves ES module specifiers used by Stimulus controllers | Keeps JS lean without a bundler |

## 3. Common error patterns & fixes

| Error message | Root cause | Fix |
| --- | --- | --- |
| `Failed to register controller … specifier was a bare specifier but was not remapped` | Missing Importmap entry (e.g. `import "swiper"`) | Run `bin/importmap pin swiper` and/or `bin/importmap pin swiper/bundle`, then import `swiper/bundle` inside the controller |
| `The response (200) did not contain the expected <turbo-frame id="…"> and will be ignored` | Controller answered without the frame wrapper Turbo expected | Ensure the response includes `<turbo-frame id="…">` or switch to full page navigation (`data-turbo="false"`/`turbo-visit-control="reload"`) |
| `TypeError: NetworkError when attempting to fetch resource` (Turbo visit) | Fetch failed: bad route, 500 error, CSP block, or pinning issue | Check Network tab + server logs to find the failing request |
| `downloadable font: rejected by sanitizer` | Font blocked by Firefox due to MIME/CORS/CSP | Verify font asset headers or host over HTTPS |

## 4. Debugging workflow

1. **Browser developer tools**
   - **Network tab**: filter `XHR`/`Fetch`, locate the Turbo frame request (`src=` URL). A `pending` or errored request explains the infinite loader.
   - **Disable cache** and retry (`Ctrl+Shift+R`) to ensure fresh assets.
   - **Preview** the response; confirm the `<turbo-frame id>` matches the original frame.
   - **Console**: look for Stimulus registration errors, Importmap issues, CSP warnings.
2. **Stimulus diagnostics**
   - When you see `Failed to register controller`, the controller never connected. Fix the Importmap, reload, and check `connect()` logs.
   - Use `data-action="turbo:frame-load->controller#method"` to verify frames invoke expected behaviour after load.
3. **Server logs**
   - `tail -f log/development.log` while reproducing the bug.
   - Ensure the controller action runs and returns `200`. If it renders a partial, make sure it wraps the frame or responds with Turbo Stream helpers.
4. **Turbo Stream validation**
   - Prefer `render turbo_stream: turbo_stream.replace("events_upcoming", partial: ...)` when replacing nodes; Turbo will serialise proper `<turbo-stream>` tags.
   - For frame navigation, use `turbo_frame_request?` guards to tailor the response:
     ```ruby
     def upcoming
       @events = Event.upcoming.by_date.limit(6)
       if turbo_frame_request?
         render partial: "home/upcoming_events", locals: { events: @events }
       else
         render :index
       end
     end
     ```

## 5. Importmap workflow

- Never edit `bin/importmap`; it is an executable. Use the CLI:
  ```bash
  bin/importmap pin swiper
  bin/importmap pin swiper/bundle
  ```
- Confirm `config/importmap.rb` now lists the pins and that `vendor/javascript/` contains the downloaded files.
- In Stimulus controllers, import the pinned name exactly:
  ```js
  import Swiper from "swiper/bundle"
  ```
- When removing a library, run `bin/importmap unpin module` to keep the map tidy.

## 6. Turbo Frames best practices

- **Match IDs**: the HTML returned to a frame request must contain `id="…"` equal to the original frame.
- **Provide fallbacks**: render a full template when `turbo_frame_request?` is false (direct navigation or crawlers).
- **Lazy loading**: use `loading="lazy"` with a `src` attribute (as on the home page) to defer fetching until the frame enters the viewport.
- **Partial composition**: keep heavy logic out of the controller; use presenters/services if data shaping is complex.

## 7. Turbo Streams & Solid Cable

- For real-time updates, enqueue Solid Queue jobs that broadcast via `Turbo::StreamsChannel`.
- Always scope stream identifiers (e.g. `turbo_stream_from [:events, current_user.id]`) to avoid leaking data across roles.
- Pair stream broadcasts with optimistic UI updates only when validation cannot fail; otherwise wait for the server response.

## 8. Tools & references

- [Hotwire documentation](https://hotwired.dev/) — official Turbo + Stimulus guides.
- [Rails 8.1 Guides](https://guides.rubyonrails.org/) — especially the Hotwire section.
- Browser extensions like the Turbo DevTools panel help visualise frame swaps.
- Keep an eye on `log/development.log` and consider enabling verbose Turbo logging by adding `Turbo::Drive.logger = Rails.logger` in development when investigating stubborn issues.

---

Maintain this guide whenever you introduce new Turbo Frames/Streams so future contributors can rely on up-to-date patterns tailored to Le Circographe.

