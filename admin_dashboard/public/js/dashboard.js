document.addEventListener('DOMContentLoaded', () => {
  const body = document.body;
  const page = body.dataset.page;
  const sidebar = document.getElementById('sidebar');
  const overlay = document.getElementById('overlay');
  const toggle = document.getElementById('mobileNavToggle');
  const searchInput = document.getElementById('pageSearch');
  const toastStack = document.getElementById('toastStack');

  const parseJSONScript = (id, fallback) => {
    const el = document.getElementById(id);
    if (!el?.textContent) return fallback;

    try {
      return JSON.parse(el.textContent);
    } catch (_) {
      return fallback;
    }
  };

  const setSidebarOpen = (isOpen) => {
    if (!sidebar || !overlay) return;
    sidebar.classList.toggle('open', isOpen);
    overlay.classList.toggle('show', isOpen);
    body.classList.toggle('menu-open', isOpen);
    toggle?.setAttribute('aria-expanded', String(isOpen));
  };

  const showToast = (message, type = 'success') => {
    if (!toastStack || !message) return;
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `<span class="material-symbols-outlined">${type === 'success' ? 'check_circle' : 'error'}</span><span>${message}</span>`;
    toastStack.appendChild(toast);
    requestAnimationFrame(() => toast.classList.add('show'));
    setTimeout(() => {
      toast.classList.remove('show');
      setTimeout(() => toast.remove(), 220);
    }, 3200);
  };

  const setButtonLoading = (button, isLoading) => {
    if (!button) return;
    button.disabled = isLoading;
    button.classList.toggle('is-loading', isLoading);
  };

  const closeModal = (modal) => {
    if (!modal) return;
    modal.classList.remove('show');
    modal.setAttribute('aria-hidden', 'true');
    if (!document.querySelector('.modal-shell.show')) {
      overlay?.classList.remove('show');
      body.classList.remove('modal-open');
    }
  };

  const openModal = (modal) => {
    if (!modal) return;
    modal.classList.add('show');
    modal.setAttribute('aria-hidden', 'false');
    overlay?.classList.add('show');
    body.classList.add('modal-open');
  };

  toggle?.addEventListener('click', () => {
    setSidebarOpen(!sidebar?.classList.contains('open'));
  });

  overlay?.addEventListener('click', () => {
    setSidebarOpen(false);
    document.querySelectorAll('.modal-shell.show').forEach((modal) => closeModal(modal));
  });

  window.addEventListener('resize', () => {
    if (window.innerWidth > 980) {
      setSidebarOpen(false);
    }
  });

  searchInput?.addEventListener('input', (event) => {
    const query = event.target.value.trim().toLowerCase();
    const rows = document.querySelectorAll('[data-search-row]');

    rows.forEach((row) => {
      const haystack = (row.getAttribute('data-search-row') || '').toLowerCase();
      row.style.display = haystack.includes(query) ? '' : 'none';
    });
  });

  document.querySelectorAll('[data-close-modal]').forEach((button) => {
    button.addEventListener('click', () => closeModal(button.closest('.modal-shell')));
  });

  document.querySelectorAll('[data-open-modal]').forEach((button) => {
    button.addEventListener('click', () => {
      const modal = document.getElementById(button.dataset.openModal);
      if (modal) openModal(modal);
    });
  });

  const chartCanvas = document.getElementById('dashboardChart');
  if (chartCanvas && window.Chart && window.STATS) {
    new Chart(chartCanvas, {
      type: 'bar',
      data: {
        labels: ['Users', 'Field Workers', 'Farmers', 'Crops', 'Open Queries', 'Resolved Queries'],
        datasets: [{
          data: [
            window.STATS.totalUsers,
            window.STATS.totalFieldworkers,
            window.STATS.totalFarmers,
            window.STATS.totalCrops,
            window.STATS.openQueries,
            window.STATS.resolvedQueries,
          ],
          backgroundColor: ['#2e7d32', '#66bb6a', '#0d631b', '#ffb74d', '#fb8c00', '#476644'],
          borderRadius: 14,
          borderSkipped: false,
        }],
      },
      options: {
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { color: '#40493d', font: { weight: '700' } },
          },
          y: {
            beginAtZero: true,
            grid: { color: 'rgba(191, 202, 186, 0.18)' },
            ticks: { color: '#40493d' },
          },
        },
      },
    });
  }

  const request = async (url, options = {}) => {
    const response = await fetch(url, {
      headers: {
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      },
      ...options,
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok || payload.success === false) {
      throw new Error(payload.message || 'Request failed');
    }

    return payload;
  };

  if (page === 'farmers') {
    const data = parseJSONScript('farmersData', { farmers: [], fieldworkers: [] });
    const farmerMap = new Map((data.farmers || []).map((farmer) => [String(farmer._id || farmer.id), farmer]));
    const detailGrid = document.getElementById('farmerDetailGrid');
    const farmerViewModal = document.getElementById('farmerViewModal');
    const farmerFormModal = document.getElementById('farmerFormModal');
    const farmerForm = document.getElementById('farmerForm');
    const farmerFormTitle = document.getElementById('farmerFormTitle');
    const farmerFormEyebrow = document.getElementById('farmerFormEyebrow');
    const createLoginCheckbox = document.getElementById('farmerCreateLogin');
    const loginPasswordWrap = document.getElementById('farmerLoginPasswordWrap');
    const loginPassword = document.getElementById('farmerPassword');
    const deleteModal = document.getElementById('confirmDeleteModal');
    const deleteMessage = document.getElementById('deleteModalMessage');
    const confirmDeleteButton = document.getElementById('confirmDeleteButton');
    let pendingDeleteUrl = null;
    let pendingDeleteLabel = null;

    const formatValue = (value) => value || 'N/A';

    const renderDetail = (farmer) => {
      if (!detailGrid || !farmer) return;
      detailGrid.innerHTML = `
        <div class="detail-item"><span>Farmer Name</span><strong>${formatValue(farmer.name)}</strong></div>
        <div class="detail-item"><span>Farmer ID</span><strong class="mono">${formatValue(farmer._id || farmer.id)}</strong></div>
        <div class="detail-item"><span>Village</span><strong>${formatValue(farmer.village)}</strong></div>
        <div class="detail-item"><span>Assigned Fieldworker</span><strong>${formatValue(farmer.createdBy?.name)}</strong></div>
        <div class="detail-item"><span>Mobile Number</span><strong>${formatValue(farmer.mobile)}</strong></div>
        <div class="detail-item"><span>Login Status</span><strong>${farmer.userId ? 'Enabled' : 'Not Linked'}</strong></div>
        <div class="detail-item"><span>Sync Status</span><strong>${formatValue(farmer.syncStatus || 'PENDING')}</strong></div>
        <div class="detail-item full"><span>Address</span><strong>${formatValue(farmer.address)}</strong></div>
      `;
    };

    const syncPasswordVisibility = () => {
      const shouldShow = createLoginCheckbox?.checked;
      if (!loginPasswordWrap || !loginPassword) return;
      loginPasswordWrap.hidden = !shouldShow;
      loginPassword.required = shouldShow;
    };

    const fillForm = (farmer) => {
      farmerForm.reset();
      document.getElementById('farmerId').value = farmer?._id || farmer?.id || '';
      document.getElementById('farmerName').value = farmer?.name || '';
      document.getElementById('farmerVillage').value = farmer?.village || '';
      document.getElementById('farmerMobile').value = farmer?.mobile || '';
      document.getElementById('farmerAddress').value = farmer?.address || '';
      document.getElementById('farmerAssignment').value = farmer?.createdBy?._id || '';
      document.getElementById('farmerSyncStatus').value = farmer?.syncStatus || 'PENDING';
      createLoginCheckbox.checked = false;
      createLoginCheckbox.disabled = Boolean(farmer?.userId);
      syncPasswordVisibility();
    };

    createLoginCheckbox?.addEventListener('change', syncPasswordVisibility);

    document.querySelectorAll('[data-action="view-farmer"]').forEach((button) => {
      button.addEventListener('click', () => {
        const farmer = farmerMap.get(button.dataset.id);
        renderDetail(farmer);
        openModal(farmerViewModal);
      });
    });

    document.querySelectorAll('[data-action="edit-farmer"]').forEach((button) => {
      button.addEventListener('click', () => {
        const farmer = farmerMap.get(button.dataset.id);
        farmerFormTitle.textContent = 'Edit Farmer';
        farmerFormEyebrow.textContent = 'Registry Update';
        fillForm(farmer);
        openModal(farmerFormModal);
      });
    });

    document.querySelectorAll('[data-mode="create"][data-open-modal="farmerFormModal"]').forEach((button) => {
      button.addEventListener('click', () => {
        farmerFormTitle.textContent = 'Add Farmer';
        farmerFormEyebrow.textContent = 'New Registry Entry';
        fillForm(null);
      });
    });

    document.querySelectorAll('[data-action="delete-record"]').forEach((button) => {
      button.addEventListener('click', () => {
        pendingDeleteUrl = button.dataset.deleteUrl;
        pendingDeleteLabel = button.dataset.recordLabel;
        deleteMessage.textContent = `Are you sure you want to delete this farmer${pendingDeleteLabel ? `, ${pendingDeleteLabel}` : ''}?`;
        openModal(deleteModal);
      });
    });

    confirmDeleteButton?.addEventListener('click', async () => {
      if (!pendingDeleteUrl) return;
      setButtonLoading(confirmDeleteButton, true);
      try {
        await request(pendingDeleteUrl, { method: 'DELETE' });
        showToast('Farmer deleted successfully');
        window.location.reload();
      } catch (error) {
        showToast(error.message, 'error');
      } finally {
        setButtonLoading(confirmDeleteButton, false);
      }
    });

    farmerForm?.addEventListener('submit', async (event) => {
      event.preventDefault();
      const submitButton = farmerForm.querySelector('button[type="submit"]');
      const formData = new FormData(farmerForm);
      const id = formData.get('id');
      const payload = Object.fromEntries(formData.entries());
      payload.createLoginAccount = createLoginCheckbox.checked;
      if (!payload.accountPassword) delete payload.accountPassword;
      if (!payload.createdBy) delete payload.createdBy;
      delete payload.id;

      setButtonLoading(submitButton, true);
      try {
        await request(id ? `/farmers/${id}` : '/farmers', {
          method: id ? 'PUT' : 'POST',
          body: JSON.stringify(payload),
        });
        showToast(id ? 'Farmer updated successfully' : 'Farmer created successfully');
        window.location.reload();
      } catch (error) {
        showToast(error.message, 'error');
      } finally {
        setButtonLoading(submitButton, false);
      }
    });
  }

  if (page === 'users') {
    const data = parseJSONScript('usersData', { users: [] });
    const userMap = new Map((data.users || []).map((user) => [String(user._id || user.id), user]));
    const formModal = document.getElementById('fieldworkerFormModal');
    const form = document.getElementById('fieldworkerForm');
    const formTitle = document.getElementById('userFormTitle');
    const formEyebrow = document.getElementById('userFormEyebrow');
    const passwordInput = document.getElementById('userPassword');
    const deleteModal = document.getElementById('confirmDeleteModal');
    const deleteMessage = document.getElementById('deleteModalMessage');
    const confirmDeleteButton = document.getElementById('confirmDeleteButton');
    let pendingDeleteUrl = null;

    const fillUserForm = (user) => {
      form.reset();
      document.getElementById('userId').value = user?._id || user?.id || '';
      document.getElementById('userName').value = user?.name || '';
      document.getElementById('userRole').value = user?.role || 'fieldworker';
      document.getElementById('userEmail').value = user?.email || '';
      document.getElementById('userMobile').value = user?.mobile || '';
      passwordInput.required = !user;
    };

    document.querySelectorAll('[data-mode="create"][data-open-modal="fieldworkerFormModal"]').forEach((button) => {
      button.addEventListener('click', () => {
        formTitle.textContent = 'Add Fieldworker';
        formEyebrow.textContent = 'Workforce Control';
        fillUserForm(null);
      });
    });

    document.querySelectorAll('[data-action="edit-user"]').forEach((button) => {
      button.addEventListener('click', () => {
        const user = userMap.get(button.dataset.id);
        formTitle.textContent = 'Edit Fieldworker';
        formEyebrow.textContent = 'Account Update';
        fillUserForm(user);
        openModal(formModal);
      });
    });

    document.querySelectorAll('[data-action="delete-record"]').forEach((button) => {
      button.addEventListener('click', () => {
        pendingDeleteUrl = button.dataset.deleteUrl;
        deleteMessage.textContent = `Are you sure you want to delete this fieldworker${button.dataset.recordLabel ? `, ${button.dataset.recordLabel}` : ''}?`;
        openModal(deleteModal);
      });
    });

    confirmDeleteButton?.addEventListener('click', async () => {
      if (!pendingDeleteUrl) return;
      setButtonLoading(confirmDeleteButton, true);
      try {
        await request(pendingDeleteUrl, { method: 'DELETE' });
        showToast('Fieldworker deleted successfully');
        window.location.reload();
      } catch (error) {
        showToast(error.message, 'error');
      } finally {
        setButtonLoading(confirmDeleteButton, false);
      }
    });

    form?.addEventListener('submit', async (event) => {
      event.preventDefault();
      const submitButton = form.querySelector('button[type="submit"]');
      const formData = new FormData(form);
      const id = formData.get('id');
      const payload = Object.fromEntries(formData.entries());
      delete payload.id;
      if (!payload.password) delete payload.password;

      setButtonLoading(submitButton, true);
      try {
        await request(id ? `/users/${id}` : '/users', {
          method: id ? 'PUT' : 'POST',
          body: JSON.stringify(payload),
        });
        showToast(id ? 'Fieldworker updated successfully' : 'Fieldworker created successfully');
        window.location.reload();
      } catch (error) {
        showToast(error.message, 'error');
      } finally {
        setButtonLoading(submitButton, false);
      }
    });
  }
});
