/**
 * Health Code Activity State Management
 * Handles logic for pr1-activity-detail.html
 */

document.addEventListener('DOMContentLoaded', () => {
  initActivityState();
});

function initActivityState() {
  const profile = JSON.parse(localStorage.getItem('aidiet_profile')) || {};
  let activityLog = JSON.parse(localStorage.getItem('aidiet_activity_log'));
  
  // Initialize mock data if none exists
  if (!activityLog) {
    activityLog = getMockActivityData();
    localStorage.setItem('aidiet_activity_log', JSON.stringify(activityLog));
  }

  // Get target workouts per week
  let targetWorkouts = 3; // Default
  if (profile.activity_frequency) {
    const map = {
      '1 раз': 1,
      '2 раза': 2,
      '3 раза': 3,
      '4 и более': 4,
      'Не готов(а) сейчас': 0
    };
    targetWorkouts = map[profile.activity_frequency] || 3;
  }
  
  if (targetWorkouts === 0) targetWorkouts = 1; // Prevent div by 0 in UI

  // Render Activity Screen
  renderActivitySummary(activityLog, targetWorkouts);
  renderWeeklyBarChart(activityLog);
  renderSteps(activityLog);
  renderWorkoutList(activityLog);

  // Attach FAB Event
  const fab = document.querySelector('.fab');
  if (fab) {
    fab.addEventListener('click', handleAddWorkout);
  }
  
  // Attach Tab Toggles
  const toggles = document.querySelectorAll('.toggle-item');
  toggles.forEach(btn => {
    btn.addEventListener('click', (e) => {
      toggles.forEach(t => t.classList.remove('active'));
      e.target.classList.add('active');
    });
  });
}

function getMockActivityData() {
  const today = new Date();
  const dayMs = 24 * 60 * 60 * 1000;
  
  return {
    steps: {
      current: Math.floor(8000 + Math.random() * 2000),
      target: 10000
    },
    workouts: [
      {
        id: 'w1',
        type: 'Силовая тренировка',
        icon: 'ph-barbell',
        duration_minutes: 45,
        burned_kcal: 280,
        timestamp: new Date(today.getTime() - 4 * dayMs).toISOString(),
        date_label: 'Пн, 15 апр' // Will be regenerated below
      },
      {
        id: 'w2',
        type: 'Бег',
        icon: 'ph-person-simple-run',
        duration_minutes: 30,
        burned_kcal: 220,
        timestamp: new Date(today.getTime() - 2 * dayMs).toISOString(),
        date_label: 'Ср, 17 апр'
      },
      {
        id: 'w3',
        type: 'Ходьба',
        icon: 'ph-person-simple-walk',
        duration_minutes: 30,
        burned_kcal: 180,
        timestamp: new Date(today.getTime()).toISOString(),
        date_label: 'Сегодня'
      }
    ]
  };
}

function renderActivitySummary(log, targetWorkouts) {
  const currentWorkouts = log.workouts.length;
  let totalMins = 0;
  let totalKcal = 0;
  
  log.workouts.forEach(w => {
    totalMins += w.duration_minutes;
    totalKcal += w.burned_kcal;
  });

  const hours = Math.floor(totalMins / 60);
  const mins = totalMins % 60;
  const timeStr = hours > 0 ? `${hours} ч ${mins} мин` : `${mins} мин`;

  const ringValEl = document.querySelector('.ring-val');
  if (ringValEl) ringValEl.textContent = `${currentWorkouts}/${targetWorkouts}`;

  // Update ring stroke
  const ringSvg = document.querySelector('.ring-svg circle:nth-child(2)');
  if (ringSvg) {
    const circumference = 2 * Math.PI * 54; // 339.29
    const percentage = Math.min(1, currentWorkouts / targetWorkouts);
    const offset = circumference - (percentage * circumference);
    ringSvg.style.strokeDashoffset = offset;
  }

  const statValues = document.querySelectorAll('.stat-value');
  if (statValues.length >= 2) {
    statValues[0].textContent = timeStr;
    statValues[1].textContent = `${totalKcal} ккал`;
  }
}

function renderWeeklyBarChart(log) {
  // Aggregate minutes by day of week (0-6, 0=Sun in JS)
  const today = new Date();
  const dayOfWk = today.getDay(); // 0 is Sunday
  
  // Transform to Mon-Sun (0-6)
  const todayIdx = dayOfWk === 0 ? 6 : dayOfWk - 1;
  
  const dailyMins = [0, 0, 0, 0, 0, 0, 0];
  
  log.workouts.forEach(w => {
    const wDate = new Date(w.timestamp);
    // Check if it's within the last 7 days
    if ((today.getTime() - wDate.getTime()) < 7 * 24 * 60 * 60 * 1000) {
      let wIdx = wDate.getDay();
      wIdx = wIdx === 0 ? 6 : wIdx - 1;
      dailyMins[wIdx] += w.duration_minutes;
    }
  });

  const maxMins = Math.max(...dailyMins, 60); // min max is 60
  
  const bars = document.querySelectorAll('.bar');
  if (bars.length === 7) {
    for (let i = 0; i < 7; i++) {
      const percentage = (dailyMins[i] / maxMins) * 100;
      bars[i].style.height = `${percentage}%`;
      
      // Highlight today
      if (i === todayIdx) {
        bars[i].classList.add('today');
      } else {
        bars[i].classList.remove('today');
      }
    }
  }
}

function renderSteps(log) {
  const steps = log.steps || { current: 3000, target: 10000 };
  
  const stepsVal = document.querySelector('.steps-val');
  const stepsTarget = document.querySelector('.steps-target');
  const stepsFill = document.querySelector('.steps-fill');
  
  if (stepsVal) stepsVal.textContent = `${steps.current.toLocaleString('ru-RU')} шагов`;
  if (stepsTarget) stepsTarget.textContent = `Цель: ${steps.target.toLocaleString('ru-RU')}`;
  
  if (stepsFill) {
    const p = Math.min(100, (steps.current / steps.target) * 100);
    stepsFill.style.width = `${p}%`;
  }
}

function renderWorkoutList(log) {
  const container = document.querySelector('.workout-list');
  if (!container) return;
  
  container.innerHTML = '';
  
  if (!log.workouts || log.workouts.length === 0) {
    container.innerHTML = '<div style="text-align: center; color: var(--color-text-secondary); padding: 20px;">Нет тренировок</div>';
    return;
  }

  // Sort by date descending
  const sorted = [...log.workouts].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

  sorted.forEach(w => {
    const div = document.createElement('div');
    div.className = 'workout-item';
    div.innerHTML = `
      <div class="workout-icon"><i class="ph ${w.icon}"></i></div>
      <div class="workout-info">
        <div class="workout-name">${w.type}</div>
        <div class="workout-meta">${w.date_label} &middot; ${w.duration_minutes} мин</div>
      </div>
      <span class="workout-kcal">${w.burned_kcal} ккал</span>
    `;
    container.appendChild(div);
  });
}

function handleAddWorkout() {
  // Demo function to add a new generic workout
  let log = JSON.parse(localStorage.getItem('aidiet_activity_log'));
  if (!log) log = { steps: { current: 0, target: 10000 }, workouts: [] };
  
  const today = new Date();
  const dateOptions = { weekday: 'short', month: 'short', day: 'numeric' };
  
  const newWorkout = {
    id: 'w' + Date.now(),
    type: 'Функциональная тренировка',
    icon: 'ph-person-arms-spread',
    duration_minutes: 40,
    burned_kcal: 250,
    timestamp: today.toISOString(),
    date_label: 'Сегодня · ' + today.toLocaleDateString('ru-RU', dateOptions).replace('.', '')
  };
  
  log.workouts.push(newWorkout);
  localStorage.setItem('aidiet_activity_log', JSON.stringify(log));
  
  // Re-init state to update UI
  initActivityState();
  
  // Show quick notification
  alert('Добавлена новая тренировка (Demo)');
}
