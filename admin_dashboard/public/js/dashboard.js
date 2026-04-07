document.addEventListener('DOMContentLoaded', () => {
    const hamburger = document.getElementById('hamburger');
    const sidebar = document.querySelector('.sidebar');
    const overlay = document.getElementById('overlay');
    const navItems = document.querySelectorAll('.nav-item');

    const setSidebarOpen = (isOpen) => {
        if (!sidebar || !overlay) {
            return;
        }

        sidebar.classList.toggle('open', isOpen);
        overlay.classList.toggle('show', isOpen);
        document.body.classList.toggle('sidebar-open', isOpen);
        hamburger?.setAttribute('aria-expanded', String(isOpen));
    };

    hamburger?.addEventListener('click', () => {
        const isOpen = !sidebar?.classList.contains('open');
        setSidebarOpen(isOpen);
    });

    overlay?.addEventListener('click', () => {
        setSidebarOpen(false);
    });

    navItems.forEach((item) => {
        item.addEventListener('click', () => {
            if (window.innerWidth <= 1100) {
                setSidebarOpen(false);
            }
        });
    });

    window.addEventListener('resize', () => {
        if (window.innerWidth > 1100) {
            setSidebarOpen(false);
        }
    });

    const path = location.pathname;
    navItems.forEach(i => {
        if (i.getAttribute('href') === path) i.classList.add('active');
    });

    const ctx = document.getElementById('dashboardChart');
    if (ctx) {
        new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['Users', 'Field Workers', 'Farmers', 'Crops', 'Open Queries', 'Resolved Queries'],
                datasets: [{
                    data: [
                        STATS.totalUsers,
                        STATS.totalFieldworkers,
                        STATS.totalFarmers,
                        STATS.totalCrops,
                        STATS.openQueries,
                        STATS.resolvedQueries
                    ],
                    backgroundColor: ['#2196f3', '#4caf50', '#ff9800', '#7b61ff', '#ff7043', '#26a69a'],
                    borderRadius: 8
                }]
            },
            options: {
                plugins: { legend: { display: false } },
                scales: { y: { beginAtZero: true } }
            }
        });
    }
});
