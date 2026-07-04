# API contract Portal SI

Sumber: `api-portalsi/routes/api.php`, controller, model, event, dan `routes/channels.php`. Semua path di bawah relatif terhadap `API_BASE_URL` dan memakai prefix `/api`. `Auth` berarti Laravel Sanctum bearer yang diteruskan BFF. `Verified` berarti `auth:sanctum` + middleware `verified.api` (verifikasi email), bukan badge `is_verified`.

## Konvensi umum

- Header JSON: `Accept: application/json`.
- Upload menggunakan `multipart/form-data`; jangan menetapkan boundary manual.
- Error validasi Laravel lazimnya `422 {message, errors}`, tetapi `PortfolioController` mengembalikan map error langsung.
- `401` mengakhiri sesi BFF. `403` harus dibedakan antara email belum verified, privacy, ownership, dan role/policy.
- Media URL bisa absolut atau path storage; client menormalisasi melalui allowlist base media.
- Response memiliki beberapa keluarga paginator; schema domain wajib, tidak boleh satu cast generik longgar.

## Public dan auth

| Method/path                             | Guard                                  | Input                                                                                               | Response penting / status                                                                                             |
| --------------------------------------- | -------------------------------------- | --------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `POST /register`                        | Public                                 | JSON `username` regex alnum/`.`/`_`, `full_name`, `email`, `password` min 6, optional role `teacher | parent                                                                                                                | student       | other` | `201 {message, verification_email_status, token, user}`; 403 bila role dev; 422 field errors |
| `POST /login-check`                     | Public                                 | `username`, `password`                                                                              | `{success,user:{id,username,full_name,role},groups}`; 401 invalid. Tidak menghasilkan token                           |
| `POST /register-teachers`               | Public (security gap)                  | `teachers[]` dengan username/password dan optional identity                                         | `201 {message,count,users}`; bulk, auto verified, auto join group 1–6                                                 |
| `POST /register-parent`                 | Public (security gap)                  | `username`, `password` min 1                                                                        | `201 {message,token,user}`, auto verified                                                                             |
| `POST /login`                           | Public                                 | `login` username/email, `password`                                                                  | `200 {code:1001,token,user}`; 401 code 2001; 403 code 2002 + `verification_email_status` missing/cooldown/sent/failed |
| `POST /fcm/register`                    | Route public; controller requires auth | `fcm_token`                                                                                         | `{message}`; 401 bila `Auth::id()` kosong                                                                             |
| `GET /email/verify/{id}/{hash}`         | Signed URL                             | path + signature query                                                                              | redirect `https://portalsi.com/verified-success`; 403 invalid hash                                                    |
| `POST /email/verification-notification` | Auth                                   | —                                                                                                   | `{message,verification_email_status}`; 200/500                                                                        |
| `POST /email/resend-verification`       | Public                                 | `login`, `password`                                                                                 | status `already_verified                                                                                              | missing_email | sent   | failed`; 401/422/500 sesuai kondisi                                                          |
| `POST /forgot-password`                 | Public                                 | `email`                                                                                             | `{message,status}`; 404 invalid_user, 409 duplicate_email, 429 throttled, 500 failed                                  |
| `POST /reset-password`                  | Public                                 | `token,email,password,password_confirmation`                                                        | `{message}`; 200 success, 400 invalid token/user/throttle                                                             |
| `POST /bind-email`                      | Auth                                   | unique `email`                                                                                      | `{message,verification_email_status}`; 400 already bound, 422 invalid, 500 send failed                                |
| `GET /profile/{username}`               | Public, optional auth context          | query `page`, `per_page`                                                                            | profile fields + counts + `recent_posts` + `pagination`; privacy may hide posts                                       |
| `POST /logout`                          | Auth                                   | —                                                                                                   | deletes current Sanctum token; `{message}`                                                                            |
| `GET /user`                             | Auth                                   | query `page`, `per_page`                                                                            | own profile, email/email_verified, counts, recent posts, pagination                                                   |

## Account dan social graph

| Method/path                            | Guard               | Input                                                                                                 | Response penting / status                                                   |
| -------------------------------------- | ------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `GET /account/is-private`              | Auth                | —                                                                                                     | bare JSON number `0` atau `1`                                               |
| `POST /account/settings`               | Verified, multipart | optional username/full_name/email/bio/is_private; `profile_picture` image ≤10MB; `banner` image ≤20MB | `{message,user}`; 422                                                       |
| `PUT /account/password`                | Verified            | `current_password`, `new_password` min 6                                                              | `{message}`; 422 current password wrong                                     |
| `DELETE /account/delete`               | Verified            | no re-auth input                                                                                      | `{message}`; langsung menghapus user/media                                  |
| `GET /mutuals`                         | Auth                | `per_page`                                                                                            | standard Laravel paginator of compact user                                  |
| `GET /users/search`                    | Auth                | at least one of `username`, `full_name`; `per_page`                                                   | standard paginator; 400 missing query; 404 no results                       |
| `GET /users/{id}/followers`            | Auth                | `page`,`per_page`                                                                                     | `{followers_count,followers,pagination}`                                    |
| `GET /users/{id}/following`            | Auth                | `page`,`per_page`                                                                                     | `{following_count,following,pagination}`                                    |
| `POST /follow/{id}`                    | Verified            | target path                                                                                           | `201 {message,status:'accepted'                                             | 'pending'}`; 403 self; 409 duplicate |
| `DELETE /unfollow/{id}`                | Verified            | target path                                                                                           | `{message}`; 404 not following                                              |
| `GET /followers/pending`               | Auth                | —                                                                                                     | `{pending_requests_count,pending_requests}`; 403 if own account not private |
| `POST /followers/{follower_id}/accept` | Auth                | —                                                                                                     | `{message}`; 403 non-private; 404 no pending                                |
| `POST /followers/{follower_id}/reject` | Auth                | —                                                                                                     | `{message}`; 403 non-private; 404 no pending                                |
| `GET /suggestions`                     | Verified            | —                                                                                                     | `{count,users:[user...]}`                                                   |

## Post, feed, comment, like, bookmark

Post entity berasal dari Eloquent dan umumnya mencakup `post_id,user_id,caption,media_url,thumbnail_url,location,is_archived,is_video,music_*,created_at,updated_at`, relasi `user,tags,mentions`, counts, `is_liked`, dan `is_bookmarked`.

| Method/path                          | Guard               | Input                                                                                                                                             | Response penting / status                                                                                  |
| ------------------------------------ | ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `GET /posts`                         | Auth                | `page`; server hardcode 2 item/page                                                                                                               | `{current_page,per_page,total,next_page_url,prev_page_url,last_page_url,feed}`; feed union post/suggestion |
| `GET /posts/{id}`                    | Auth                | —                                                                                                                                                 | full Post; 403 private owner not accessible; 404                                                           |
| `POST /posts`                        | Verified, multipart | required `media` jpg/jpeg/png/mp4/mov/webm/avi/3gp/mkv ≤500MB; optional thumbnail image ≤50MB, caption/location/is_archived/is_video/music fields | `201 {message,post}`; hashtag dan mention diproses dari caption                                            |
| `POST /posts/{id}/update`            | Verified, multipart | same optional fields; media optional                                                                                                              | `{message,post}`; 403 non-owner                                                                            |
| `DELETE /posts/{id}`                 | Verified            | —                                                                                                                                                 | `{message}`; 403 non-owner                                                                                 |
| `GET /explore`                       | Auth                | `page`,`per_page` default 15, optional `tag`, sort `random                                                                                        | popular                                                                                                    | newest`          | standard Laravel paginator (`data,current_page,last_page,next_page_url,...`) |
| `GET /circle-avatar/{id}`            | Auth                | user id                                                                                                                                           | `{user_id,profile_picture_url}`                                                                            |
| `GET /clips/{id}`                    | Auth                | start post id; query mengikuti controller                                                                                                         | `{clips,...}` custom response; video posts around starting id                                              |
| `GET /posts/{post_id}/likes`         | Auth                | —                                                                                                                                                 | array `{id,post_id,user,created_at,is_following_status}`                                                   |
| `POST /posts/{post_id}/like`         | Verified            | —                                                                                                                                                 | toggle; `{message:'Post liked'                                                                             | 'Post unliked'}` |
| `GET /posts/{post_id}/comments`      | Auth                | —                                                                                                                                                 | array/tree comment dengan user/replies/like state sesuai controller                                        |
| `POST /posts/{post_id}/comments`     | Verified            | `content`, optional existing `parent_comment_id`                                                                                                  | comment response; creates comment/reply notification                                                       |
| `PUT /comments/{id}`                 | Verified            | `content`                                                                                                                                         | `{message,data}`; 403 non-owner                                                                            |
| `DELETE /comments/{id}`              | Verified            | —                                                                                                                                                 | `{message}`; 403 non-owner                                                                                 |
| `POST /comments/{comment_id}/like`   | Verified            | —                                                                                                                                                 | comment like response; conflict/idempotency ditangani adapter                                              |
| `DELETE /comments/{comment_id}/like` | Verified            | —                                                                                                                                                 | unlike response                                                                                            |
| `GET /bookmarks`                     | Auth                | —                                                                                                                                                 | collection posts bookmarked by current user                                                                |
| `POST /bookmarks/{postId}`           | Auth                | —                                                                                                                                                 | `{message,bookmark}`, idempotent via firstOrCreate                                                         |
| `DELETE /bookmarks/{postId}`         | Auth                | —                                                                                                                                                 | `{message}`; 404 if absent                                                                                 |

## Story

Story fields: `story_id,user_id,media_url,caption,type,music_*,music_display_style,music_sticker_position_x/y,color_pallete,created_at,expires_at` plus user/view state depending endpoint.

| Method/path                       | Guard               | Input                | Response penting / status                                        |
| --------------------------------- | ------------------- | -------------------- | ---------------------------------------------------------------- |
| `GET /stories/feed`               | Auth                | —                    | grouped users with active stories and seen metadata              |
| `GET /stories/feed/user/{userId}` | Auth                | —                    | `{user,stories,...}`; privacy/status checks from controller      |
| `GET /stories/my`                 | Auth                | —                    | array own active stories                                         |
| `POST /stories`                   | Verified, multipart | required type `image | video                                                            | music`; optional media jpg/jpeg/png/mp4/mov/webm/mp3/wav ≤500MB, caption, music fields, positions, JSON-string `color_pallete` | `201 {message,story}` |
| `DELETE /stories/{id}`            | Verified            | —                    | `{message}`; owner-only behavior                                 |
| `POST /stories/{id}/view`         | Verified            | —                    | `{message,view_count}`; update-or-create semantics in controller |
| `GET /stories/{id}/viewers`       | Verified            | —                    | `{story_id,viewers_count,viewers}`; owner check                  |
| `GET /stories/user/{userId}`      | Verified            | —                    | active stories for user with view info                           |
| `GET /stories/my/archived`        | Verified            | `page`,`per_page`    | `{stories,pagination}` custom paginator                          |

## Notification dan announcement

| Method/path                            | Guard               | Input                                                                                  | Response penting / status                                                         |
| -------------------------------------- | ------------------- | -------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| `GET /notifications`                   | Auth                | `page`,`per_page` default 15                                                           | `{notifications,pagination}`; generated message, sender, related_post_id, is_read |
| `PATCH /notifications/{id}/read`       | Auth                | —                                                                                      | `{message}`; 404 not owned/missing                                                |
| `PATCH /notifications/read/all`        | Auth                | —                                                                                      | `{message}`; route-order risk dicatat di gaps                                     |
| `GET /announcements`                   | Auth                | —                                                                                      | unpaginated array with creator                                                    |
| `GET /announcements/pinned`            | Auth                | —                                                                                      | unpaginated pinned array                                                          |
| `POST /announcements`                  | Verified, multipart | optional title ≤255, content, image ≤50MB, poll_data array/JSON string, pinned boolean | Announcement, 201; controller tidak role-check                                    |
| `POST /announcements/{announcement}`   | Verified, multipart | fields same as create                                                                  | Announcement; policy update                                                       |
| `DELETE /announcements/{announcement}` | Verified            | —                                                                                      | `{message:'Deleted'}`; policy delete                                              |

## Direct message dan chat list

DirectMessage fields meliputi `message_id,sender_id,receiver_id,content,media_url,is_story_response,story_id,responded_media_url,sent_at,is_read`.

| Method/path                                 | Guard           | Input                                                                                           | Response penting / status                                                                    |
| ------------------------------------------- | --------------- | ----------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `POST /messages/send`                       | Auth, multipart | receiver_id; optional content; media jpg/jpeg/png/mp4/mov/webm/pdf ≤50MB; story response fields | `201 {message,data}`; backend tidak mensyaratkan content/media salah satu terisi             |
| `GET /messages/conversation/{user_id}`      | Auth            | —                                                                                               | unpaginated ascending DirectMessage array; own outgoing forced `is_read=true` in response    |
| `GET /messages/conversation-from/{user_id}` | Auth            | —                                                                                               | unpaginated incoming-only array                                                              |
| `PATCH /messages/{id}/read`                 | Auth            | —                                                                                               | receiver-owned only; `{message}`                                                             |
| `PATCH /messages/user/{user_id}/read`       | Auth            | —                                                                                               | `{message,updated_count}`                                                                    |
| `DELETE /messages/{id}`                     | Auth            | —                                                                                               | sender-owned hard delete + media delete; `{message}`                                         |
| `GET /messages/chat-list`                   | Auth            | —                                                                                               | unpaginated union: direct `{type:'user',conversation,last_chat}` dan group flat object       |
| `GET /messages/unread/{user_id}`            | Auth            | —                                                                                               | `{unread_count,messages}`                                                                    |
| `GET /messages/channels`                    | Auth            | —                                                                                               | array wire-like channel strings; DM strings already prefixed `private-dm.*`, group `group.*` |

## Group dan group message

| Method/path                                        | Guard                 | Input                                                                                     | Response penting / status                                             |
| -------------------------------------------------- | --------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------------- |
| `GET /special-groups`                              | Auth; parent/teacher  | —                                                                                         | array group 1–6 with `unread_message_count` as string; 403 other role |
| `POST /groups`                                     | Verified, multipart   | name; optional description, avatar/cover jpg/jpeg/png ≤10MB, members string[] identifiers | `{message,group}`; owner added as admin                               |
| `POST /groups/{group}/join`                        | Verified              | —                                                                                         | `{message}`; 409 already member                                       |
| `POST /groups/{group}/leave`                       | Verified              | —                                                                                         | `{message}`; owner restrictions from controller                       |
| `GET /groups/{group}`                              | Verified              | —                                                                                         | group with owner/members/role/count metadata                          |
| `PUT                                               | POST /groups/{group}` | Verified, multipart                                                                       | optional name/description/avatar/cover                                | `{message,group}`; backend method intentionally accepts POST for multipart |
| `DELETE /groups/{group}`                           | Verified              | —                                                                                         | owner authorization; `{message}`                                      |
| `GET /groups/{group}/role`                         | Verified              | —                                                                                         | current membership role/status object                                 |
| `POST /groups/{group}/members`                     | Verified              | `identifier` username/email                                                               | `{message,member}`; admin-only; 404/409                               |
| `GET /groups/{group}/members`                      | Verified              | —                                                                                         | member/user list; membership required                                 |
| `POST /groups/{group}/members/{user}/promote`      | Verified              | —                                                                                         | admin role mutation; owner/admin rules                                |
| `POST /groups/{group}/members/{user}/demote`       | Verified              | —                                                                                         | member role mutation                                                  |
| `DELETE /groups/{group}/members/{user}`            | Verified              | —                                                                                         | remove member                                                         |
| `POST /groups/{group}/members/{user}/mute`         | Verified              | —                                                                                         | set muted                                                             |
| `POST /groups/{group}/members/{user}/unmute`       | Verified              | —                                                                                         | clear muted                                                           |
| `POST /groups/{group}/messages`                    | Verified, multipart   | optional content/media ≤50MB (jpg/jpeg/png/mp4/mov/webm/pdf), optional reply_to           | `{message,data}` formatted; mentions parsed from `@username`          |
| `GET /groups/{group}/messages`                     | Verified              | optional boolean `reverse`                                                                | `{group_id,messages}` unpaginated                                     |
| `DELETE /groups/{group}/messages/{message}`        | Verified              | —                                                                                         | sender-only soft delete; `{message}`                                  |
| `POST /groups/{group}/messages/{message}/pin`      | Verified              | —                                                                                         | owner-only toggle; `{message,is_pinned}`                              |
| `POST /groups/{group}/messages/{message}/read`     | Verified              | —                                                                                         | upsert read; `{message}`                                              |
| `GET /groups/{group}/messages/{message}/read-info` | Verified              | —                                                                                         | `{message_id,reads}`                                                  |
| `GET /groups/{group}/messages/unread`              | Verified              | —                                                                                         | `{group_id,unread_messages}`                                          |

## Portfolio, history, online

| Method/path                             | Guard                        | Input                                               | Response penting / status                                            |
| --------------------------------------- | ---------------------------- | --------------------------------------------------- | -------------------------------------------------------------------- |
| `GET /portfolios`                       | Verified                     | filters aspect/user_id/year/search/sort_by/sort_dir | `{portfolios}` unpaginated; aspect randomizes order                  |
| `POST /portfolios`                      | Verified + controller access | required user_id, aspect `quran                     | it                                                                   | bahasa | karakter`, title; optional description, media jpg/jpeg/png/pdf ≤50MB, year 2000..current | `{message,portfolio}`; 422 direct field map |
| `POST /portfolios/{portfolio}`          | Verified + controller access | optional same fields except user_id                 | `{message,portfolio}`                                                |
| `DELETE /portfolios/{portfolio}`        | Verified + controller access | —                                                   | `{message}`                                                          |
| `GET /login-histories`                  | Auth                         | —                                                   | all own history, unpaginated                                         |
| `DELETE /login-histories/{id}`          | Auth                         | —                                                   | revokes token + deletes history only when ≥7 days old; 403 otherwise |
| `POST /websocket/authenticate`          | Auth                         | websocket auth payload per controller               | auth/session metadata response                                       |
| `POST /websocket/disconnect`            | Auth                         | —                                                   | `{message}`                                                          |
| `GET /websocket/online-status/{userId}` | Auth                         | —                                                   | online status payload; 404 user                                      |
| `GET /websocket/online-followers`       | Auth                         | —                                                   | `{count,followers:[...]}`                                            |
| `GET /websocket/online-count`           | Auth                         | —                                                   | `{count}`                                                            |
| `POST /websocket/update-activity`       | Auth                         | —                                                   | `{message}`                                                          |

## Pagination schemas

| Nama internal    | Endpoint                                                   | Shape                                                                                        |
| ---------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `FeedPage`       | `/posts`                                                   | root metadata + `feed`; no numeric `last_page`; `next_page_url` authoritative                |
| `LaravelPage<T>` | `/explore`, `/users/search`, `/mutuals`                    | `data,current_page,last_page,per_page,total,next_page_url,...`                               |
| `NamedPage<T>`   | followers/following/notifications/story archive/profile    | domain array key + nested `pagination:{current_page,last_page,per_page,total,next_page_url}` |
| `Unpaged<T>`     | announcements, bookmarks, conversations, groups, portfolio | array or named collection; no fabricated cursor                                              |

## Realtime contract

Pusher/Reverb wire menambahkan prefix `private-` pada `PrivateChannel`, tetapi nama logical di bawah mengikuti PHP. Event dengan `broadcastAs()` didengarkan menggunakan nama persis (Echo lazim memakai awalan `.`).

| Logical channel        | Authorization                 | Event names yang ditemukan                                                                   | Pemakaian                                |
| ---------------------- | ----------------------------- | -------------------------------------------------------------------------------------------- | ---------------------------------------- |
| `App.Models.User.{id}` | hanya user id sama            | `chat.updated`, `notification.new`                                                           | chat list dan variant notifikasi         |
| `user.{userId}`        | hanya user id sama            | `user.followed`, `user.unfollowed`, `notification.created`, juga like/comment owner          | notifikasi/social graph                  |
| `post.{postId}`        | setiap user authenticated     | `like.created`, `comment.created`, `comment.published`, `comment.updated`, `comment.deleted` | detail/card post                         |
| `dm.{minId-maxId}`     | peserta id dalam segment      | `dm.new`                                                                                     | direct message utama                     |
| `group.{groupId}`      | member group                  | `group.new`, `group.updated`, `member.added`, `member.removed`                               | group chat/member updates                |
| `chat.direct.{roomId}` | participant                   | `message.sent`                                                                               | legacy/alternate direct event            |
| `chat.group.{groupId}` | member                        | `message.sent`                                                                               | legacy/alternate group event             |
| `story.{storyId}`      | returns presence user payload | story/viewer event belum terbukti dipancarkan controller                                     | jangan subscribe sampai emitter terbukti |
| `announcements`        | event public                  | `announcement.created`                                                                       | announcement refresh/upsert              |
| `test-channel`         | any auth                      | test event                                                                                   | development only                         |

Event `MessageRead` dan `MessageDeleted` masih memakai placeholder `channel-name` dan tidak dipancarkan controller; keduanya tidak menjadi kontrak production. Client wajib dedupe event dengan entity id, cleanup saat unmount, resubscribe setelah reconnect, exponential backoff+jitter, dan menghentikan polling fallback ketika realtime pulih.

## Third-party contracts

| Service      | URL                                                      | Aturan frontend                                                     |
| ------------ | -------------------------------------------------------- | ------------------------------------------------------------------- |
| Ranking      | `https://santriboard.vercel.app/api/student/leaderboard` | BFF proxy, timeout/cache/stale fallback, runtime schema             |
| Music search | `https://itunes.apple.com/search`                        | BFF allowlist, debounce/cancel, hanya simpan metadata yang didukung |
| Geocoding    | `https://nominatim.openstreetmap.org`                    | identify request, debounce/cache, OSM attribution                   |
| Store        | `https://store.portalsi.com/`                            | exact-origin allowlist, external navigation safe                    |
| Akun RG      | configured `akunrg.com` flow                             | tidak aktif di browser sebelum server-side secret exchange tersedia |
