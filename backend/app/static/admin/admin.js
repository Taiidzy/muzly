const apiBase = `${window.location.origin}/api`;
const tokenKey = 'muzly_admin_token';

const state = {
  token: localStorage.getItem(tokenKey),
  tracks: [],
  playlists: [],
  selectedPlaylistId: null,
  editingTrackId: null,
  editingPlaylistId: null,
  loading: false,
};

const els = {
  loginPanel: document.getElementById('login-panel'),
  uploadPanel: document.getElementById('upload-panel'),
  importPanel: document.getElementById('import-panel'),
  statsPanel: document.getElementById('stats-panel'),
  tracksPanel: document.getElementById('tracks-panel'),
  playlistsPanel: document.getElementById('playlists-panel'),
  loginForm: document.getElementById('login-form'),
  uploadForm: document.getElementById('upload-form'),
  importForm: document.getElementById('import-form'),
  playlistForm: document.getElementById('playlist-form'),
  importStatus: document.getElementById('import-status'),
  stats: document.getElementById('stats'),
  tracksTable: document.getElementById('tracks-table'),
  playlistsTable: document.getElementById('playlists-table'),
  playlistDetail: document.getElementById('playlist-detail'),
  trackSearch: document.getElementById('track-search'),
  statusPill: document.getElementById('status-pill'),
  apiBase: document.getElementById('api-base'),
  toast: document.getElementById('toast'),
  refreshBtn: document.getElementById('refresh-btn'),
  playlistRefresh: document.getElementById('playlist-refresh'),
  logoutBtn: document.getElementById('logout-btn'),
  reuploadModal: document.getElementById('reupload-modal'),
  reuploadForm: document.getElementById('reupload-form'),
  reuploadCancel: document.getElementById('reupload-cancel'),
};

function showToast(message, tone = 'info') {
  els.toast.textContent = message;
  els.toast.classList.add('show');
  if (tone === 'error') {
    els.toast.style.borderColor = 'rgba(207, 102, 121, 0.6)';
  } else if (tone === 'success') {
    els.toast.style.borderColor = 'rgba(122, 166, 143, 0.6)';
  } else {
    els.toast.style.borderColor = 'rgba(255, 255, 255, 0.08)';
  }
  setTimeout(() => {
    els.toast.classList.remove('show');
  }, 2400);
}

async function apiFetch(path, options = {}) {
  const headers = options.headers || {};
  if (state.token) {
    headers.Authorization = `Bearer ${state.token}`;
  }
  const response = await fetch(`${apiBase}${path}`, {
    ...options,
    headers,
  });
  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    const message = error.detail || error.error || `Request failed (${response.status})`;
    throw new Error(message);
  }
  return response;
}

function setAuthenticated(isAuthed) {
  const display = isAuthed ? 'block' : 'none';
  els.loginPanel.style.display = isAuthed ? 'none' : 'block';
  els.uploadPanel.style.display = display;
  els.importPanel.style.display = display;
  els.statsPanel.style.display = display;
  els.tracksPanel.style.display = display;
  els.playlistsPanel.style.display = display;
  els.refreshBtn.style.display = display;
  els.playlistRefresh.style.display = display;
  els.logoutBtn.style.display = display;
  els.statusPill.textContent = isAuthed ? 'Online' : 'Disconnected';
  els.statusPill.classList.toggle('online', isAuthed);
}

async function checkAuth() {
  if (!state.token) {
    setAuthenticated(false);
    return false;
  }
  try {
    await apiFetch('/auth/me');
    setAuthenticated(true);
    return true;
  } catch (err) {
    state.token = null;
    localStorage.removeItem(tokenKey);
    setAuthenticated(false);
    return false;
  }
}

async function login(username, password) {
  const body = new URLSearchParams();
  body.append('username', username);
  body.append('password', password);

  const response = await fetch(`${apiBase}/auth/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body,
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new Error(error.detail || 'Login failed');
  }

  const data = await response.json();
  state.token = data.access_token;
  localStorage.setItem(tokenKey, state.token);
  setAuthenticated(true);
  showToast('Logged in', 'success');
}

function renderStats(stats) {
  if (!stats) {
    els.stats.innerHTML = '<div class="muted">No data</div>';
    return;
  }
  const cards = [
    { label: 'Tracks', value: stats.tracks?.total ?? 0 },
    { label: 'Ready', value: stats.tracks?.ready ?? 0 },
    { label: 'Failed', value: stats.tracks?.failed ?? 0 },
    { label: 'Playlists', value: stats.playlists ?? 0 },
    { label: 'Favorites', value: stats.favorites ?? 0 },
    { label: 'Users', value: stats.users ?? 0 },
  ];
  els.stats.innerHTML = cards
    .map(
      (card) => `
      <div class="stat-card">
        <div class="label">${card.label}</div>
        <div class="value">${card.value}</div>
      </div>`
    )
    .join('');
}

function renderTracks(tracks) {
  if (!tracks.length) {
    els.tracksTable.innerHTML = '<div class="muted">No tracks yet</div>';
    return;
  }

  const header = `
    <div class="table-row header">
      <div>Title</div>
      <div>Artist</div>
      <div>Album</div>
      <div>Status</div>
      <div></div>
    </div>`;

  const rows = tracks
    .map((track) => {
      const status = track.status || 'ready';
      const isEditing = state.editingTrackId === String(track.id);
      const isFailed = status === 'failed';
      return `
        <div class="table-row ${isEditing ? 'editing' : ''}">
          <div>
            ${
              isEditing
                ? `<input type="text" data-field="title" data-id="${track.id}" value="${track.title || ''}" />`
                : `<div>${track.title}</div>`
            }
            <div class="muted">${track.id}</div>
          </div>
          <div>
            ${
              isEditing
                ? `<input type="text" data-field="artist" data-id="${track.id}" value="${track.artist || ''}" />`
                : `${track.artist || '-'}`
            }
          </div>
          <div>
            ${
              isEditing
                ? `<input type="text" data-field="album" data-id="${track.id}" value="${track.album || ''}" />`
                : `${track.album || '-'}`
            }
          </div>
          <div><span class="badge ${status}">${status}</span></div>
          <div class="actions">
            ${
              isEditing
                ? `<button class="ghost" data-action="save" data-id="${track.id}">Save</button>
                   <button class="ghost" data-action="cancel" data-id="${track.id}">Cancel</button>`
                : `<button class="ghost" data-action="edit" data-id="${track.id}">Edit</button>`
            }
            <button class="ghost" data-action="play" data-id="${track.id}">Play</button>
            ${isFailed ? `<button class="ghost" data-action="reupload" data-id="${track.id}">Re-upload</button>` : ''}
            <button class="ghost" data-action="delete" data-id="${track.id}">Delete</button>
          </div>
        </div>`;
    })
    .join('');

  els.tracksTable.innerHTML = header + rows;
}

async function loadTracks() {
  const response = await apiFetch('/tracks?page=1&page_size=200');
  const data = await response.json();
  const items = Array.isArray(data) ? data : data.items || [];
  state.tracks = items;
  renderTracks(state.tracks);
}

async function loadStats() {
  const response = await apiFetch('/admin/stats');
  const data = await response.json();
  renderStats(data);
}

function renderPlaylists(playlists) {
  if (!playlists.length) {
    els.playlistsTable.innerHTML = '<div class="muted">No playlists yet</div>';
    return;
  }

  const header = `
    <div class="table-row header">
      <div>Name</div>
      <div>Visibility</div>
      <div>Tracks</div>
      <div>Updated</div>
      <div></div>
    </div>`;

  const rows = playlists
    .map((playlist) => {
      const visibility = (playlist.visibility || 'private').toLowerCase();
      const label = visibility === 'public' ? 'PUBLIC' : 'PRIVATE';
      const isEditing = state.editingPlaylistId === String(playlist.id);
      return `
        <div class="table-row ${isEditing ? 'editing' : ''}">
          <div>
            ${
              isEditing
                ? `<input type="text" data-field="name" data-id="${playlist.id}" value="${playlist.name || playlist.title || ''}" />`
                : `<div>${playlist.name || playlist.title}</div>`
            }
            ${
              isEditing
                ? `<input type="text" data-field="description" data-id="${playlist.id}" value="${playlist.description || ''}" />`
                : ''
            }
            <div class="muted">${playlist.id}</div>
          </div>
          <div>
            ${
              isEditing
                ? `<select data-field="visibility" data-id="${playlist.id}">
                    <option value="PRIVATE" ${label === 'PRIVATE' ? 'selected' : ''}>PRIVATE</option>
                    <option value="PUBLIC" ${label === 'PUBLIC' ? 'selected' : ''}>PUBLIC</option>
                  </select>`
                : `<span class="badge">${label}</span>`
            }
          </div>
          <div>${playlist.track_count ?? playlist.trackCount ?? 0}</div>
          <div>${playlist.updated_at ? new Date(playlist.updated_at).toLocaleString() : '-'}</div>
          <div class="actions">
            ${
              isEditing
                ? `<button class="ghost" data-action="save" data-id="${playlist.id}">Save</button>
                   <button class="ghost" data-action="cancel" data-id="${playlist.id}">Cancel</button>`
                : `<button class="ghost" data-action="open" data-id="${playlist.id}">Open</button>
                   <button class="ghost" data-action="edit" data-id="${playlist.id}">Edit</button>
                   <button class="ghost" data-action="delete" data-id="${playlist.id}">Delete</button>`
            }
          </div>
        </div>`;
    })
    .join('');

  els.playlistsTable.innerHTML = header + rows;
}

async function loadPlaylists() {
  const response = await apiFetch('/playlists?page=1&page_size=200');
  const data = await response.json();
  state.playlists = data.items || [];
  renderPlaylists(state.playlists);
  if (state.selectedPlaylistId) {
    await loadPlaylistDetail(state.selectedPlaylistId);
  }
}

async function loadPlaylistDetail(playlistId) {
  const response = await apiFetch(`/playlists/${playlistId}`);
  const data = await response.json();
  renderPlaylistDetail(data);
  renderPlaylistSearchResults('');
}

function renderPlaylistDetail(playlist) {
  if (!playlist) {
    els.playlistDetail.innerHTML = '';
    return;
  }
  state.selectedPlaylistId = playlist.id;
  const tracks = playlist.tracks || [];
  const trackRows = tracks.length
    ? tracks
        .map((entry) => {
          const track = entry.track || entry;
          return `
          <div class="track-row">
            <div class="meta">
              <span>${track.title || 'Unknown'}</span>
              <span class="muted">${track.artist || '-'}</span>
            </div>
            <div class="actions">
              <button class="ghost" data-action="remove-track" data-track-id="${track.id}" data-playlist-id="${playlist.id}">Remove</button>
            </div>
          </div>`;
        })
        .join('')
    : '<div class="muted">No tracks in this playlist</div>';

  els.playlistDetail.innerHTML = `
    <h3>${playlist.name || playlist.title}</h3>
    <p class="muted">${playlist.description || 'No description'}</p>
    <div class="inline-form">
      <label>
        Search track
        <input type="search" name="trackSearch" id="playlist-track-search" placeholder="Type title or artist..." />
      </label>
    </div>
    <div class="search-results" id="playlist-search-results"></div>
    <div class="track-list">${trackRows}</div>
  `;
}

function renderPlaylistSearchResults(query) {
  const container = document.getElementById('playlist-search-results');
  if (!container) return;
  const needle = query.trim().toLowerCase();
  if (!needle) {
    container.innerHTML = '<div class="muted">Start typing to search tracks</div>';
    return;
  }
  const results = state.tracks.filter((track) => {
    return (
      (track.title || '').toLowerCase().includes(needle) ||
      (track.artist || '').toLowerCase().includes(needle) ||
      (track.album || '').toLowerCase().includes(needle)
    );
  });
  if (!results.length) {
    container.innerHTML = '<div class="muted">No matches</div>';
    return;
  }
  container.innerHTML = results
    .slice(0, 20)
    .map(
      (track) => `
      <div class="search-row">
        <div class="meta">
          <span>${track.title}</span>
          <span class="muted">${track.artist || '-'} · ${track.album || 'Unknown Album'}</span>
        </div>
        <button class="ghost" data-action="add-track" data-track-id="${track.id}">Add</button>
      </div>`
    )
    .join('');
}

function filterTracks(query) {
  const needle = query.trim().toLowerCase();
  if (!needle) {
    renderTracks(state.tracks);
    return;
  }
  const filtered = state.tracks.filter((track) => {
    return (
      (track.title || '').toLowerCase().includes(needle) ||
      (track.artist || '').toLowerCase().includes(needle) ||
      (track.album || '').toLowerCase().includes(needle)
    );
  });
  renderTracks(filtered);
}

async function uploadTrack(formData) {
  await apiFetch('/tracks/upload', {
    method: 'POST',
    body: formData,
  });
  showToast('Track uploaded', 'success');
  await loadTracks();
  await loadStats();
}

async function reuploadTrack(trackId, formData) {
  await apiFetch(`/tracks/${trackId}/reupload`, {
    method: 'POST',
    body: formData,
  });
  showToast('Track re-uploaded', 'success');
  await loadTracks();
  await loadStats();
}

async function importJson(formData) {
  const response = await apiFetch('/import/json', {
    method: 'POST',
    body: formData,
  });
  const task = await response.json();
  const taskId = task.task_id;
  els.importStatus.textContent = `Import started: ${taskId}`;
  showToast('Import started', 'success');
  await pollImport(taskId);
}

async function pollImport(taskId) {
  let keepGoing = true;
  while (keepGoing) {
    await new Promise((resolve) => setTimeout(resolve, 2000));
    const response = await apiFetch(`/import/status/${taskId}`);
    const data = await response.json();
    const status = data.status || 'pending';
    els.importStatus.textContent = `Status: ${status} | ${data.processed_tracks}/${data.total_tracks} processed | ${data.failed_tracks} failed`;
    if (status === 'completed' || status === 'failed') {
      keepGoing = false;
      await loadTracks();
      await loadStats();
      showToast(`Import ${status}`, status === 'failed' ? 'error' : 'success');
    }
  }
}

async function deleteTrack(trackId) {
  await apiFetch(`/tracks/${trackId}`, { method: 'DELETE' });
  showToast('Track deleted', 'success');
  await loadTracks();
  await loadStats();
}

async function updateTrack(trackId, payload) {
  await apiFetch(`/tracks/${trackId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  showToast('Track updated', 'success');
  await loadTracks();
}

async function createPlaylist(payload) {
  await apiFetch('/playlists', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  showToast('Playlist created', 'success');
  await loadPlaylists();
  await loadStats();
}

async function updatePlaylist(playlistId, payload) {
  await apiFetch(`/playlists/${playlistId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload),
  });
  showToast('Playlist updated', 'success');
  await loadPlaylists();
}

async function deletePlaylist(playlistId) {
  await apiFetch(`/playlists/${playlistId}`, { method: 'DELETE' });
  showToast('Playlist deleted', 'success');
  if (state.selectedPlaylistId === playlistId) {
    state.selectedPlaylistId = null;
    els.playlistDetail.innerHTML = '';
  }
  await loadPlaylists();
  await loadStats();
}

async function addTrackToPlaylist(playlistId, trackId) {
  const parsedId = Number(trackId);
  if (Number.isNaN(parsedId)) {
    throw new Error('Track ID must be a number');
  }
  await apiFetch(`/playlists/${playlistId}/tracks`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ track_ids: [parsedId] }),
  });
  showToast('Track added', 'success');
  await loadPlaylistDetail(playlistId);
}

async function removeTrackFromPlaylist(playlistId, trackId) {
  await apiFetch(`/playlists/${playlistId}/tracks/${trackId}`, { method: 'DELETE' });
  showToast('Track removed', 'success');
  await loadPlaylistDetail(playlistId);
}

function bindEvents() {
  els.loginForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const form = new FormData(els.loginForm);
    const username = form.get('username');
    const password = form.get('password');
    try {
      await login(username, password);
      await refreshAll();
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  els.uploadForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const formData = new FormData(els.uploadForm);
    try {
      await uploadTrack(formData);
      els.uploadForm.reset();
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  els.reuploadForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const formData = new FormData(els.reuploadForm);
    const trackId = formData.get('track_id');
    try {
      await reuploadTrack(trackId, formData);
      els.reuploadForm.reset();
      els.reuploadModal.style.display = 'none';
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  els.reuploadCancel.addEventListener('click', () => {
    els.reuploadModal.style.display = 'none';
    els.reuploadForm.reset();
  });

  els.importForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const formData = new FormData(els.importForm);
    try {
      await importJson(formData);
      els.importForm.reset();
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  els.tracksTable.addEventListener('click', async (event) => {
    const button = event.target.closest('button[data-action]');
    if (!button) return;
    const action = button.dataset.action;
    const trackId = button.dataset.id;
    if (action === 'play') {
      const url = `${apiBase}/tracks/${trackId}/stream`;
      window.open(url, '_blank');
    }
    if (action === 'edit') {
      state.editingTrackId = String(trackId);
      renderTracks(state.tracks);
    }
    if (action === 'cancel') {
      state.editingTrackId = null;
      renderTracks(state.tracks);
    }
    if (action === 'save') {
      const row = button.closest('.table-row');
      const title = row.querySelector('input[data-field="title"]').value.trim();
      const artist = row.querySelector('input[data-field="artist"]').value.trim();
      const album = row.querySelector('input[data-field="album"]').value.trim();
      try {
        await updateTrack(trackId, {
          title,
          artist,
          album: album.length ? album : null,
        });
        state.editingTrackId = null;
      } catch (err) {
        showToast(err.message, 'error');
      }
    }
    if (action === 'delete') {
      if (confirm('Delete this track?')) {
        try {
          await deleteTrack(trackId);
        } catch (err) {
          showToast(err.message, 'error');
        }
      }
    }
    if (action === 'reupload') {
      document.getElementById('reupload-track-id').value = trackId;
      els.reuploadModal.style.display = 'flex';
    }
  });

  els.trackSearch.addEventListener('input', (event) => {
    filterTracks(event.target.value);
  });

  els.refreshBtn.addEventListener('click', () => {
    refreshAll();
  });

  els.playlistRefresh.addEventListener('click', () => {
    loadPlaylists();
  });

  els.playlistForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    const formData = new FormData(els.playlistForm);
    const payload = {
      name: formData.get('name'),
      description: formData.get('description') || null,
      visibility: formData.get('visibility') || 'PRIVATE',
    };
    try {
      await createPlaylist(payload);
      els.playlistForm.reset();
    } catch (err) {
      showToast(err.message, 'error');
    }
  });

  els.playlistsTable.addEventListener('click', async (event) => {
    const button = event.target.closest('button[data-action]');
    if (!button) return;
    const action = button.dataset.action;
    const playlistId = button.dataset.id;
    if (action === 'open') {
      await loadPlaylistDetail(playlistId);
    }
    if (action === 'edit') {
      state.editingPlaylistId = String(playlistId);
      renderPlaylists(state.playlists);
    }
    if (action === 'cancel') {
      state.editingPlaylistId = null;
      renderPlaylists(state.playlists);
    }
    if (action === 'save') {
      const row = button.closest('.table-row');
      const name = row.querySelector('input[data-field="name"]').value.trim();
      const description = row.querySelector('input[data-field="description"]').value.trim();
      const visibility = row.querySelector('select[data-field="visibility"]').value;
      try {
        await updatePlaylist(playlistId, {
          name,
          description: description.length ? description : null,
          visibility,
        });
        state.editingPlaylistId = null;
      } catch (err) {
        showToast(err.message, 'error');
      }
    }
    if (action === 'delete') {
      if (confirm('Delete this playlist?')) {
        try {
          await deletePlaylist(playlistId);
        } catch (err) {
          showToast(err.message, 'error');
        }
      }
    }
  });

  els.playlistDetail.addEventListener('click', async (event) => {
    const button = event.target.closest('button[data-action]');
    if (!button) return;
    if (button.dataset.action === 'remove-track') {
      const trackId = button.dataset.trackId;
      const playlistId = button.dataset.playlistId;
      try {
        await removeTrackFromPlaylist(playlistId, trackId);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }
    if (button.dataset.action === 'add-track') {
      const trackId = button.dataset.trackId;
      if (!state.selectedPlaylistId) return;
      try {
        await addTrackToPlaylist(state.selectedPlaylistId, trackId);
      } catch (err) {
        showToast(err.message, 'error');
      }
    }
  });

  els.playlistDetail.addEventListener('input', (event) => {
    if (event.target.id !== 'playlist-track-search') return;
    renderPlaylistSearchResults(event.target.value);
  });

  els.logoutBtn.addEventListener('click', () => {
    state.token = null;
    localStorage.removeItem(tokenKey);
    setAuthenticated(false);
  });
}

async function refreshAll() {
  try {
    await loadTracks();
    await loadPlaylists();
    await loadStats();
    if (state.selectedPlaylistId) {
      await loadPlaylistDetail(state.selectedPlaylistId);
    }
  } catch (err) {
    showToast(err.message, 'error');
  }
}

async function init() {
  els.apiBase.textContent = apiBase;
  bindEvents();
  const authed = await checkAuth();
  if (authed) {
    await refreshAll();
  }
}

init();
