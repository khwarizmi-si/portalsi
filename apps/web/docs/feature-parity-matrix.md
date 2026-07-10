# Feature parity matrix

Status setelah implementasi:

- `Selesai`: route/komponen memakai API nyata dan melewati type-check/lint/test.
- `Sebagian`: alur utama nyata, tetapi ada kapabilitas Flutter/native atau kontrak server yang belum setara.
- `Lokal`: capability browser/IndexedDB, tidak sinkron ke server.
- `Gap`: tidak ada kontrak aman atau implementasi Flutter memang placeholder.
- `Helper`: layar utilitas dilebur menjadi modal/komponen web, bukan route mandiri.

## Public, onboarding, dan app shell

| Flutter source                                  | Tujuan/perilaku                           | Route Svelte            | Endpoint utama                             | Role        | Status/catatan                                   |
| ----------------------------------------------- | ----------------------------------------- | ----------------------- | ------------------------------------------ | ----------- | ------------------------------------------------ |
| `splash_screen.dart`                            | bootstrap token/user, routing awal        | `/`                     | `GET /api/user`                            | public/auth | Fase 1; BFF cookie menggantikan token client     |
| `video_intro_screen.dart`                       | intro video                               | `/welcome`              | —                                          | public      | Fase 1; hormati reduced motion/data              |
| `welcome_page.dart`                             | welcome + Akun RG                         | `/welcome`              | belum ada SSO server                       | public      | Fase 1; Akun RG Gap sampai BFF exchange tersedia |
| `login_page.dart`                               | login username/email, verifikasi, Akun RG | `/login`                | `POST /api/login`                          | public      | Selesai; Akun RG tetap gap server                |
| `register_page.dart`                            | registrasi publik                         | `/register`             | `POST /api/register`                       | public      | Selesai; role dev dilarang                       |
| `forgot_password_page.dart`                     | kirim reset link                          | `/forgot-password`      | `POST /api/forgot-password`                | public      | Selesai                                          |
| deep link reset (Flutter service/link handling) | reset password                            | `/reset-password`       | `POST /api/reset-password`                 | public      | Integrasi                                        |
| verified redirect backend                       | sukses verifikasi                         | `/verified-success`     | signed `GET /api/email/verify/{id}/{hash}` | public      | Fase 1; backend redirect ke portalsi.com         |
| `permissions_page.dart`                         | permission onboarding native              | `/settings/preferences` | browser permissions                        | auth        | Lokal; hanya permission relevan web              |
| `download_app_prompt_page.dart`                 | ajakan unduh aplikasi                     | komponen promo          | —                                          | public/auth | Helper; tidak menghalangi web                    |
| `update_screen.dart`                            | force/update app native                   | —                       | —                                          | —           | Gap/tidak relevan untuk web deployment           |
| `main_scaffold.dart` + `bottom_navigation.dart` | shell dan 5 primary nav                   | layout `(app)`          | bootstrap domain                           | auth        | Fase 1                                           |
| `connect_data_page.dart`                        | placeholder menghubungkan data            | —                       | —                                          | auth        | Gap; tidak ada aksi/kontrak nyata                |

## Home, feed, post, explore, clips

| Flutter source                                   | Tujuan/perilaku                             | Route Svelte            | Endpoint utama                            | Role           | Status/catatan                                                |
| ------------------------------------------------ | ------------------------------------------- | ----------------------- | ----------------------------------------- | -------------- | ------------------------------------------------------------- |
| `dashboard_page.dart`                            | home feed, story, announcement, suggestions | `/home`                 | posts, stories/feed, announcements/pinned | auth           | Selesai; partial endpoint failure terisolasi                  |
| `feed_page.dart`                                 | explore/search grid                         | `/explore`              | `GET /api/explore`, `/users/search`       | auth           | Selesai                                                       |
| `post_detail.dart`                               | post + komentar/like                        | `/posts/:postId`        | posts/{id}, likes, comments               | auth           | Selesai; termasuk likers dan owner CRUD                       |
| `post_detail_page.dart`                          | wrapper detail                              | `/posts/:postId`        | sama                                      | auth           | Helper/deduplikasi                                            |
| `fullscreen_image_viewer.dart`                   | zoom media                                  | modal media             | media URL                                 | auth           | Helper                                                        |
| `full_screen_image_viewer.dart`                  | viewer duplikat                             | modal media             | media URL                                 | auth           | Helper/deduplikasi                                            |
| `image_preview_screen.dart`                      | preview sebelum upload                      | composer                | —                                         | auth+verified  | Helper                                                        |
| `preview_screen.dart`                            | preview media                               | composer                | —                                         | auth+verified  | Helper                                                        |
| `create_post_page.dart`                          | pilih/camera/draft post                     | `/create/post`          | `POST /api/posts`                         | verified       | Selesai; single media, crop, musik/lokasi BFF, IndexedDB      |
| `create_post_web_page.dart`                      | upload post khusus web                      | `/create/post`          | `POST /api/posts`                         | verified       | Digabung ke responsive composer                               |
| `edit_post_page.dart`                            | edit caption/media/music/location           | `/posts/:id`            | `POST /api/posts/{id}/update`             | owner+verified | Selesai; form owner inline                                    |
| `share_post_page.dart`                           | cari penerima dan share                     | share sheet             | Web Share/copy; DM bila dipilih           | auth           | Fase 1; tidak membuat share endpoint                          |
| `bookmarks_page.dart`                            | saved posts                                 | `/settings/saved`       | `GET /api/bookmarks`                      | auth           | Integrasi                                                     |
| `clips_viewer_page.dart`                         | vertical clips                              | `/clips/:postId`        | `GET /api/clips/{id}`                     | auth           | Fase 1 + Integrasi                                            |
| `create_clips_page.dart`                         | pilih/rekam/edit video                      | `/create/clips`         | `POST /api/posts`                         | verified       | Fase 1; capability browser nyata                              |
| `edit_clips/edit_clips_page.dart`                | cut/effect/text/sticker/draft               | composer clips          | post upload                               | verified       | Sebagian Lokal; fitur native yang tak tersedia diberi batasan |
| `edit_clips/cutout_editor_page.dart` dan widgets | editor video/cutout                         | composer clips          | —                                         | verified       | Gap/opsional browser capability; bukan janji parity palsu     |
| `drafts_page.dart`                               | daftar draft Hive                           | `/drafts`               | IndexedDB                                 | auth           | Lokal                                                         |
| `camera_page.dart`, `camera_screen.dart`         | capture media                               | composer modal          | MediaDevices                              | auth           | Lokal/capability guarded                                      |
| `camera_settings_page.dart`                      | preferensi kamera                           | `/settings/preferences` | IndexedDB                                 | auth           | Lokal                                                         |
| `osm_picker_page.dart`                           | pilih/reverse-geocode lokasi                | composer location sheet | Nominatim/OSM via BFF                     | verified       | Integrasi third-party + attribution                           |

## Story

| Flutter source               | Tujuan/perilaku                | Route Svelte            | Endpoint utama                  | Role           | Status/catatan                             |
| ---------------------------- | ------------------------------ | ----------------------- | ------------------------------- | -------------- | ------------------------------------------ |
| `story_view_page.dart`       | story viewer progresif         | `/stories/:userId`      | feed/user, view                 | auth           | Selesai; keyboard/hold/mute/navigation     |
| `story_page.dart`            | viewer alternatif              | `/stories/:userId`      | sama                            | auth           | Helper/deduplikasi                         |
| `create_story_page.dart`     | capture/pilih story            | `/create/story`         | `POST /api/stories`             | verified       | Fase 1 + Integrasi                         |
| `create_story_web_page.dart` | upload web                     | `/create/story`         | `POST /api/stories`             | verified       | Digabung ke composer responsif             |
| `story_preview_page.dart`    | crop, musik, overlay, preview  | `/create/story`         | story fields yang didukung      | verified       | Sebagian; crop/musik nyata, overlay gap    |
| `story_settings_page.dart`   | sharing/preferences            | `/settings/preferences` | —                               | auth           | Lokal/Gap                                  |
| `close_friends_page.dart`    | daftar close friends hardcoded | —                       | tidak ada                       | auth           | Gap; tidak ditampilkan sebagai fitur aktif |
| `story_viewers_list.dart`    | viewers owner                  | sheet viewer            | `GET /api/stories/{id}/viewers` | owner+verified | Selesai; termasuk delete owner             |

## Profile, social graph, portfolio, ranking

| Flutter source                             | Tujuan/perilaku                           | Route Svelte                           | Endpoint utama                | Role            | Status/catatan                                 |
| ------------------------------------------ | ----------------------------------------- | -------------------------------------- | ----------------------------- | --------------- | ---------------------------------------------- |
| `profile_page.dart`                        | profil sendiri + grids                    | `/profile`                             | `GET /api/user`, portfolios   | auth            | Fase 1 + Integrasi                             |
| `other_profile_page.dart`                  | profile orang lain/privacy/follow/message | `/u/:username`                         | profile, follow/unfollow      | public/auth     | Fase 1 + Integrasi                             |
| `edit_profile_page.dart`                   | avatar/banner/bio/identity                | `/profile/edit`                        | `POST /api/account/settings`  | verified        | Fase 1 + Integrasi                             |
| `followers_following_page.dart`            | follower/following paginated              | `/u/:username/followers`, `/following` | users/{id}/followers          | following       | auth                                           | Integrasi |
| follow request UI (other profile/services) | pending/accept/reject                     | `/settings/follow-requests`            | followers/pending + actions   | private account | Selesai                                        |
| `share_profile_page.dart`                  | share profile/QR card                     | share sheet                            | Web Share/copy                | public/auth     | Fase 1; QR hanya bila benar-benar dibuat       |
| `portfolio_page.dart`                      | hub kategori + ranking                    | `/portfolio`                           | portfolios + ranking external | auth            | Selesai; filter dan CRUD sesuai policy backend |
| `portfolio_pages.dart`                     | portfolio listing alternatif              | `/portfolio`                           | `GET /api/portfolios`         | auth            | Deduplikasi                                    |
| `portfolio_aspect_page.dart`               | filter aspek                              | `/portfolio/:aspect`                   | portfolios?aspect=            | auth            | Integrasi                                      |
| `add_portfolio_page.dart`                  | create portfolio                          | `/portfolio/new`                       | `POST /api/portfolios`        | backend-allowed | Integrasi + auth-gap warning                   |
| `student_detail_page.dart`                 | detail portfolio siswa                    | `/u/:username/portfolio`               | portfolios?user_id=           | auth            | Integrasi                                      |
| `ranking_page.dart`                        | leaderboard/search/cache                  | `/ranking`                             | Santriboard external          | auth            | Fase 1 + Integrasi BFF/stale fallback          |
| `link_santri_page.dart`                    | tautkan data siswa                        | —                                      | tidak ada Laravel route       | parent?         | Gap; jangan tampilkan tombol aktif             |

## Pesan langsung dan grup

| Flutter source                  | Tujuan/perilaku                                 | Route Svelte                    | Endpoint utama                | Role                 | Status/catatan                                           |
| ------------------------------- | ----------------------------------------------- | ------------------------------- | ----------------------------- | -------------------- | -------------------------------------------------------- |
| `message_list_page.dart`        | gabungan DM/group list                          | `/messages`                     | `GET /api/messages/chat-list` | auth                 | Fase 1 + Integrasi                                       |
| `new_message_page.dart`         | cari user untuk DM                              | `/messages/new`                 | `GET /api/users/search`       | auth                 | Fase 1 + Integrasi                                       |
| `chat_room.dart`                | DM text/media/story response/read/delete/online | `/messages/direct/:userId`      | messages/* + websocket status | auth                 | Fase 1 + Integrasi; tanpa server pagination              |
| `chat_room_page.dart`           | file kosong/alias                               | —                               | —                             | —                    | Gap; diabaikan                                           |
| `chat_info_page.dart`           | info DM/shared media                            | `/messages/direct/:userId/info` | turunan conversation          | auth                 | Fase 1; data aktual saja                                 |
| `create_group_page.dart`        | create group + members/media                    | `/groups/new`                   | `POST /api/groups`            | verified             | Selesai                                                  |
| `group_chat_room_page.dart`     | message/reply/mention/pin/read                  | `/messages/groups/:groupId`     | groups/{id}/messages/*        | member+verified      | Sebagian; nyata, tanpa server pagination/read-info sheet |
| `group_info_page.dart`          | group detail/edit/leave/delete                  | `/groups/:groupId/info`         | groups/{id}                   | member/admin/owner   | Selesai                                                  |
| `group_members_page.dart`       | list dan role action                            | `/groups/:groupId/info`         | members/*                     | member/admin/owner   | Selesai; dilebur ke info grup                            |
| `edit_group_page.dart`          | name/description/avatar/cover                   | `/groups/:groupId/info`         | POST/PUT groups/{id}          | owner sesuai backend | Selesai; dilebur ke info grup                            |
| `add_members_bottom_sheet.dart` | search/add member                               | group members sheet             | users/search + group members  | admin                | Helper + Integrasi                                       |

## Announcement, notification, store, settings

| Flutter source                  | Tujuan/perilaku                    | Route Svelte               | Endpoint utama                        | Role           | Status/catatan                                                    |
| ------------------------------- | ---------------------------------- | -------------------------- | ------------------------------------- | -------------- | ----------------------------------------------------------------- |
| `notif_page.dart`               | grouped notification + read state  | `/notifications`           | notifications + read endpoints        | auth           | Fase 1 + Integrasi                                                |
| `announcement_list_page.dart`   | list/detail media                  | `/announcements`           | announcements                         | auth           | Selesai                                                           |
| `create_announcement_page.dart` | create poll/image/pin              | `/announcements`           | `POST /api/announcements`             | teacher/dev UI | Sebagian; image/pin CRUD, poll UI belum diekspos; server role gap |
| `store_page.dart`               | WebView external store             | `/store`                   | `https://store.portalsi.com/`         | auth           | Fase 1; safe external landing                                     |
| `settings_page.dart`            | settings hub                       | `/settings`                | domain endpoints                      | auth           | Fase 1                                                            |
| `account_privacy_page.dart`     | privacy toggle                     | `/settings/privacy`        | account/is-private + account/settings | verified       | Integrasi                                                         |
| `change_password_page.dart`     | change password                    | `/settings/password`       | `PUT /api/account/password`           | verified       | Fase 1 + Integrasi                                                |
| `login_history_page.dart`       | sessions/history + revoke after 7d | `/settings/sessions`       | login-histories                       | auth           | Fase 1 + Integrasi                                                |
| archived story menu             | archive                            | `/settings/story-archive`  | stories/my/archived                   | verified       | Integrasi                                                         |
| account deletion (backend only) | destructive delete                 | `/settings/delete-account` | `DELETE /api/account/delete`          | verified       | Integrasi; re-auth server gap                                     |

## Komponen lintas fitur yang wajib dipertahankan

| Flutter source                                                                               | Parity web                                                                         |
| -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `post_card.dart`, `post_header.dart`, `post_action*.dart`, `post_info_section.dart`          | typed PostCard dengan media stabil, ownership menu, like/bookmark rollback         |
| `story_section.dart`, `story_circle.dart`, `story_content_view.dart`                         | story rail dengan seen/unseen, own/create state, keyboard/touch viewer             |
| `comment_section.dart` dan `widgets/comment_*`                                               | threaded comment, reply, edit/delete own, like toggle                              |
| `network_image_with_placeholder.dart`, `video_player_widget.dart`, `single_clip_player.dart` | media component dengan broken fallback, lazy loading, active-only playback         |
| `verified_badge.dart`, `verified_info_dialog.dart`                                           | badge visual terpisah dari email-verification guard                                |
| controllers/providers cache/navigation                                                       | server cache terpisah dari transient UI; URL menggantikan PageView-only navigation |

## Checklist parity audit berikutnya

- [ ] Setiap row dipindah ke `Selesai` hanya setelah route, state, dan test tersedia.
- [ ] Screenshot mobile/tablet/desktop ditautkan ke prototype Fase 1.
- [ ] Semua endpoint yang dipakai tiap row memiliki schema runtime.
- [ ] Role/verified/ownership dibuktikan oleh test, bukan hanya conditional rendering.
- [ ] Gap server tetap terlihat di `contract-gaps.md` dan tidak ditutupi mock.

## Bukti visual Fase 1

- [Home mobile 390×844](screenshots/home-mobile-390x844.png)
- [Home tablet 820×1180](screenshots/home-tablet-820x1180.png)
- [Home desktop 1440×1000](screenshots/home-desktop-1440x1000.png)
- [Inbox desktop 1440×1000](screenshots/messages-desktop-1440x1000.png)
- [Login mobile 390×844](screenshots/login-mobile-390x844.png)

Pemeriksaan browser pada production build mencakup 17 route prototype utama di viewport 390×844. Overflow horizontal awal pada home ditemukan di track grid utama dan telah diperbaiki; pemeriksaan ulang menunjukkan `scrollWidth <= clientWidth` untuk seluruh route tersebut.
