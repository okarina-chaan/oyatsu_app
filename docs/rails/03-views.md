# 03. ビュー構成 (ERB)

> 参照: [`02-routes-controllers.md`](./02-routes-controllers.md)

---

## 1. ディレクトリ

```
app/views/
├─ layouts/
│  └─ application.html.erb
├─ shared/
│  ├─ _app_shell_top.html.erb     # status bar + topbar スロット
│  ├─ _bottom_nav.html.erb        # 4タブ
│  ├─ _piggy_bank.html.erb        # 貯金箱 SVG
│  ├─ _coin.html.erb              # コイン SVG（partial, size 引数）
│  └─ _flash.html.erb
├─ home/
│  ├─ show.html.erb
│  └─ _effort_row.html.erb
├─ settings/
│  └─ show.html.erb
├─ effort_items/
│  ├─ _form.html.erb
│  ├─ new.html.erb
│  └─ edit.html.erb
├─ effort_checks/
│  └─ create.turbo_stream.erb     # チェック切替の差分更新
└─ snacks/
   ├─ index.html.erb
   ├─ new.html.erb
   ├─ edit.html.erb
   ├─ show.html.erb
   ├─ _form.html.erb
   └─ _snack_card.html.erb
```

---

## 2. 4画面 ⇔ ERB 対応

| モック画面    | ERB                                       | 主な partial                                |
| ------------ | ----------------------------------------- | ------------------------------------------- |
| ① ホーム     | `home/show.html.erb`                      | `shared/_piggy_bank`, `_coin`, `_bottom_nav` |
| ② 設定       | `settings/show.html.erb` + `effort_items/_form` | `_bottom_nav`                            |
| ③ おやつ記録 | `snacks/new.html.erb`                     | `snacks/_form`, `_coin`                     |
| ④ おやつ一覧 | `snacks/index.html.erb`                   | `snacks/_snack_card`, `_bottom_nav`         |

---

## 3. ホーム画面 (`home/show.html.erb`)

```erb
<div class="app-shell">
  <%= render "shared/app_shell_top" %>

  <header class="topbar">
    <div>
      <h1>
        <%= render "shared/piggy_mini" %>
        <span>おやつ貯金</span>
      </h1>
      <p class="sub"><%= l(Date.current, format: :long) %> · 今日もえらい！</p>
    </div>
  </header>

  <main class="content">
    <%# ====== 貯金箱カード ====== %>
    <section class="card piggy-hero">
      <%= render "shared/piggy_bank" %>
      <p class="balance">
        <span class="num"><%= @balance %></span>
        <span class="denom">/ <%= @cost %> <%= render "shared/coin", size: 18 %></span>
      </p>
      <p class="callout">
        <% if @remaining.zero? %>
          おやつタイム！🎉
        <% else %>
          あと <strong><%= @remaining %></strong> コインでおやつタイム！
        <% end %>
      </p>
      <div class="progress-bar">
        <div class="progress-fill" style="width: <%= (@progress * 100).round %>%"></div>
      </div>
    </section>

    <%# ====== 頑張り項目 ====== %>
    <section>
      <h2 class="section-title">
        <span class="pip"></span>
        今日の頑張り
        <span class="muted">
          <%= @effort_items.count(&:checked_on?) %> / <%= @effort_items.size %>
        </span>
      </h2>

      <ul id="effort_items" class="effort-list">
        <% @effort_items.each do |item| %>
          <%= turbo_frame_tag dom_id(item) do %>
            <%= render "home/effort_row", item: item %>
          <% end %>
        <% end %>
      </ul>
    </section>
  </main>

  <%= render "shared/bottom_nav", active: :home %>
</div>
```

---

## 4. 頑張り行 (`home/_effort_row.html.erb`)

```erb
<li class="effort-row <%= 'done' if item.checked_on? %>"
    data-controller="effort-check"
    data-effort-check-checked-value="<%= item.checked_on? %>">
  <div class="effort-text">
    <p class="effort-name"><%= item.name %></p>
    <p class="effort-meta">
      <%= render "shared/coin", size: 13, sparkle: false %>
      <span class="coin-amount">+<%= item.coins_per_check %> コイン</span>
    </p>
  </div>

  <% if item.checked_on? %>
    <%= button_to effort_item_check_path(item),
                  method: :delete,
                  form: { data: { turbo_frame: dom_id(item) } },
                  class: "check checked", aria: { label: "達成を取り消す" } do %>
      ✓
    <% end %>
  <% else %>
    <%= button_to effort_item_check_path(item),
                  method: :post,
                  form: { data: { turbo_frame: dom_id(item) } },
                  class: "check", aria: { label: "達成にする" } do %><% end %>
  <% end %>
</li>
```

---

## 5. Turbo Stream 応答 (`effort_checks/create.turbo_stream.erb`)

```erb
<%= turbo_stream.replace(dom_id(@effort_item)) do %>
  <%= render "home/effort_row", item: @effort_item %>
<% end %>

<%# コインカウンタも同時に差し替えると気持ちいい %>
<%= turbo_stream.replace "coin_balance" do %>
  <%= render "home/balance", user: Current.user %>
<% end %>
```

---

## 6. おやつ記録フォーム (`snacks/_form.html.erb`)

```erb
<%= form_with model: @snack, class: "snack-form" do |f| %>
  <%# 写真 %>
  <div class="field" data-controller="photo-preview">
    <%= f.label :photo, "写真（任意）", class: "field-label" %>
    <%= f.file_field :photo, accept: "image/*",
                     class: "photo-input",
                     data: { action: "change->photo-preview#load",
                             photo_preview_target: "input" } %>
    <div data-photo-preview-target="preview" class="photo-preview"></div>
  </div>

  <%# 名前 %>
  <div class="field">
    <%= f.label :name, "何を食べた？", class: "field-label" %>
    <%= f.text_field :name, class: "input", placeholder: "例: 苺ショートケーキ" %>
  </div>

  <%# 種類 (chip group) %>
  <div class="field" data-controller="chip-group">
    <span class="field-label">種類</span>
    <div class="chips">
      <% Snack.categories.each_key do |key| %>
        <label class="chip" data-action="click->chip-group#select">
          <%= f.radio_button :category, key, class: "hidden" %>
          <%= t("snacks.categories.#{key}") %>
        </label>
      <% end %>
    </div>
  </div>

  <%# 満足度 hearts %>
  <div class="field"
       data-controller="heart-rating"
       data-heart-rating-value-value="<%= @snack.rating %>">
    <span class="field-label">満足度</span>
    <div class="heart-row">
      <% (1..5).each do |i| %>
        <button type="button"
                class="heart"
                data-action="click->heart-rating#pick"
                data-heart-rating-index-param="<%= i %>"
                data-heart-rating-target="heart">♡</button>
      <% end %>
      <%= f.hidden_field :rating, data: { heart_rating_target: "input" } %>
    </div>
  </div>

  <%# 感想 %>
  <div class="field">
    <%= f.label :note, "感想メモ", class: "field-label" %>
    <%= f.text_area :note, rows: 4, class: "input" %>
  </div>

  <%= f.hidden_field :eaten_on, value: Date.current %>

  <%= f.submit "#{Current.user.snack_cost_in_coins}コイン使ってごほうびを記録 🎀",
               class: "btn-primary" %>
<% end %>
```

---

## 7. SVG partial について

`icons.jsx` の以下を ERB partial 化してそのまま貼る：

| 元 (JSX)        | partial                       |
| --------------- | ----------------------------- |
| `<PiggyBank />` | `shared/_piggy_bank.html.erb` |
| `<PiggyMini />` | `shared/_piggy_mini.html.erb` |
| `<Coin />`      | `shared/_coin.html.erb` (locals: `size`, `sparkle`) |
| `<SnackCake />` | `snacks/_thumb_yougashi.html.erb`  |
| `<SnackMochi />`| `snacks/_thumb_wagashi.html.erb`   |
| `<SnackChips />`| `snacks/_thumb_shoppai.html.erb`   |

snack カードは `snack.category` でファイル名を切り替え：

```erb
<%= render "snacks/thumb_#{snack.category}", snack: snack %>
```
