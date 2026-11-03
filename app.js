const { createClient } = window.supabase;
const client = createClient(
  window.SUD_CONFIG.supabaseUrl,
  window.SUD_CONFIG.supabasePublishableKey
);

const $ = (id) => document.getElementById(id);

function setAuthMessage(message, good = false) {
  const el = $("authMessage");
  el.textContent = message || "";
  el.style.color = good ? "#4ade80" : "";
}

function openAuth(tab = "login") {
  $("authModal").classList.remove("hidden");
  $("authModal").setAttribute("aria-hidden", "false");
  switchAuthTab(tab);
}

function closeAuth() {
  $("authModal").classList.add("hidden");
  $("authModal").setAttribute("aria-hidden", "true");
  setAuthMessage("");
}

function switchAuthTab(tab) {
  document.querySelectorAll(".auth-tab").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.authTab === tab);
  });
  $("loginForm").classList.toggle("hidden", tab !== "login");
  $("signupForm").classList.toggle("hidden", tab !== "signup");
  setAuthMessage("");
}

function showPage(page) {
  document.querySelectorAll(".page").forEach(el => el.classList.remove("active"));
  const target = $(`${page}Page`);
  if (target) target.classList.add("active");
  if (page === "users") loadUsers();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

async function loadUsers() {
  const grid = $("usersGrid");
  grid.innerHTML = `<div class="loading">Loading users…</div>`;

  const { data, error } = await client
    .from("profiles")
    .select("id, username, avatar_url, bio, created_at")
    .order("created_at", { ascending: false });

  if (error) {
    grid.innerHTML = `<div class="loading">Couldn't load users yet.</div>`;
    console.error(error);
    return;
  }

  if (!data.length) {
    grid.innerHTML = `<div class="empty-state"><span>👥</span><h2>No users yet</h2><p>Be the first person to register.</p></div>`;
    return;
  }

  grid.innerHTML = data.map(user => {
    const initial = (user.username || "?").charAt(0).toUpperCase();
    const avatar = user.avatar_url
      ? `<div class="avatar"><img src="${escapeHtml(user.avatar_url)}" alt=""></div>`
      : `<div class="avatar">${escapeHtml(initial)}</div>`;
    return `
      <article class="user-card" data-user-id="${user.id}">
        ${avatar}
        <div class="user-name">${escapeHtml(user.username)}</div>
        <div class="role">Deluxe member</div>
      </article>`;
  }).join("");

  grid.querySelectorAll(".user-card").forEach(card => {
    card.addEventListener("click", () => openProfile(card.dataset.userId));
  });
}

async function openProfile(userId) {
  const { data, error } = await client
    .from("profiles")
    .select("id, username, avatar_url, bio, created_at")
    .eq("id", userId)
    .single();

  if (error) return;

  const initial = (data.username || "?").charAt(0).toUpperCase();
  const avatar = data.avatar_url
    ? `<div class="avatar"><img src="${escapeHtml(data.avatar_url)}" alt=""></div>`
    : `<div class="avatar">${escapeHtml(initial)}</div>`;
  const joined = new Date(data.created_at).toLocaleDateString(undefined, {
    year: "numeric", month: "long", day: "numeric"
  });

  $("profileContent").innerHTML = `
    <div class="profile-head">
      ${avatar}
      <div><h2>${escapeHtml(data.username)}</h2><div class="role">Deluxe member</div></div>
    </div>
    <p class="profile-bio">${escapeHtml(data.bio || "This user hasn't written a bio yet.")}</p>
    <div class="profile-meta">Member since ${joined}</div>
  `;
  $("profileModal").classList.remove("hidden");
}

function closeProfile() {
  $("profileModal").classList.add("hidden");
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, ch => ({
    "&":"&amp;", "<":"&lt;", ">":"&gt;", '"':"&quot;", "'":"&#039;"
  }[ch]));
}

async function refreshAccountUI() {
  const { data: { user } } = await client.auth.getUser();

  if (!user) {
    $("accountButton").textContent = "Sign In";
    $("accountButton").onclick = () => openAuth("login");
    $("heroAccountButton").textContent = "Create an Account";
    $("heroAccountButton").onclick = () => openAuth("signup");
    return;
  }

  const { data: profile } = await client
    .from("profiles")
    .select("username")
    .eq("id", user.id)
    .maybeSingle();

  $("accountButton").textContent = profile?.username || "Account";
  $("accountButton").onclick = () => openProfile(user.id);
  $("heroAccountButton").textContent = "View My Profile";
  $("heroAccountButton").onclick = () => openProfile(user.id);
}

async function signUp() {
  const username = $("signupUsername").value.trim();
  const email = $("signupEmail").value.trim();
  const password = $("signupPassword").value;

  if (!/^[A-Za-z0-9_]{3,24}$/.test(username)) {
    setAuthMessage("Username must be 3–24 characters using letters, numbers, or underscores.");
    return;
  }
  if (password.length < 8) {
    setAuthMessage("Password must be at least 8 characters.");
    return;
  }

  $("signupSubmit").disabled = true;
  setAuthMessage("Creating your account…");

  const { data, error } = await client.auth.signUp({
    email,
    password,
    options: { data: { username } }
  });

  $("signupSubmit").disabled = false;

  if (error) {
    setAuthMessage(error.message);
    return;
  }

  if (data.user) {
    setAuthMessage(
      data.session
        ? "Account created! You're signed in."
        : "Account created. Check your email to confirm your account.",
      true
    );
    if (data.session) {
      setTimeout(closeAuth, 600);
    }
  }
}

async function logIn() {
  const email = $("loginEmail").value.trim();
  const password = $("loginPassword").value;

  $("loginSubmit").disabled = true;
  setAuthMessage("Signing you in…");

  const { error } = await client.auth.signInWithPassword({ email, password });

  $("loginSubmit").disabled = false;

  if (error) {
    setAuthMessage(error.message);
    return;
  }

  setAuthMessage("Signed in!", true);
  setTimeout(closeAuth, 400);
}

async function resetPassword() {
  const email = $("loginEmail").value.trim();
  if (!email) {
    setAuthMessage("Enter your email first, then try again.");
    return;
  }

  const redirectTo = window.location.origin + window.location.pathname;
  const { error } = await client.auth.resetPasswordForEmail(email, { redirectTo });

  setAuthMessage(error ? error.message : "Password reset email sent.", !error);
}

document.querySelectorAll("[data-page]").forEach(el => {
  el.addEventListener("click", e => {
    e.preventDefault();
    showPage(el.dataset.page);
  });
});

document.querySelectorAll("[data-auth-tab]").forEach(el => {
  el.addEventListener("click", () => switchAuthTab(el.dataset.authTab));
});

document.querySelectorAll("[data-close-auth]").forEach(el => el.addEventListener("click", closeAuth));
document.querySelectorAll("[data-close-profile]").forEach(el => el.addEventListener("click", closeProfile));

$("signupSubmit").addEventListener("click", signUp);
$("loginSubmit").addEventListener("click", logIn);
$("resetPassword").addEventListener("click", resetPassword);

client.auth.onAuthStateChange(() => refreshAccountUI());
refreshAccountUI();
loadUsers();
