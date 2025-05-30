document.addEventListener('DOMContentLoaded', function() {
    // Language settings
    let currentLanguage = 'ja'; // Default language is Japanese
    const languageToggle = document.getElementById('language-toggle');
    
    // Add click event to language toggle
    languageToggle.addEventListener('click', function() {
        // Toggle language
        if (currentLanguage === 'ja') {
            currentLanguage = 'en';
            languageToggle.classList.add('en-active');
            document.documentElement.lang = 'en';
            document.title = document.title.replace('パーキングアプリ', 'Parking App');
        } else {
            currentLanguage = 'ja';
            languageToggle.classList.remove('en-active');
            document.documentElement.lang = 'ja';
            document.title = document.title.replace('Parking App', 'パーキングアプリ');
        }
        
        // Update all elements with data-ja and data-en attributes
        const elementsToUpdate = document.querySelectorAll('[data-ja][data-en]');
        elementsToUpdate.forEach(function(element) {
            element.textContent = element.getAttribute(`data-${currentLanguage}`);
        });
        
        // Update language selector display
        if (currentLanguage === 'en') {
            document.querySelector('.jp').style.color = '#3366CC';
            document.querySelector('.en').style.color = '#333333';
        } else {
            document.querySelector('.jp').style.color = '#333333';
            document.querySelector('.en').style.color = '#3366CC';
        }
    });
    
    // Add ripple effect to buttons
    const buttons = document.querySelectorAll('.primary-button');
    buttons.forEach(function(button) {
        button.addEventListener('click', function(e) {
            const ripple = this.querySelector('.ripple');
            if (ripple) {
                ripple.style.animation = 'none';
                setTimeout(() => {
                    ripple.style.animation = 'ripple 1s ease-out';
                }, 10);
            }
        });
    });
    
    // Add click animation to other buttons
    const socialButtons = document.querySelectorAll('.social-button');
    socialButtons.forEach(function(button) {
        button.addEventListener('click', function() {
            this.style.transform = 'scale(0.98)';
            setTimeout(() => {
                this.style.transform = 'scale(1)';
            }, 150);
        });
    });
    
    // Make input fields active on click
    const inputFields = document.querySelectorAll('.input-field');
    inputFields.forEach(function(field) {
        field.addEventListener('click', function() {
            // Remove active class from all fields
            inputFields.forEach(f => f.classList.remove('active'));
            // Add active class to clicked field
            this.classList.add('active');
        });
    });

    // Handle screen navigation if elements exist
    setupScreenNavigation();
});

function setupScreenNavigation() {
    // Navigation between screens
    const showLoginBtn = document.getElementById('show-login');
    const showRegisterBtn = document.getElementById('show-register');
    const backToLoginBtn = document.getElementById('back-to-login');
    const showVerificationBtn = document.getElementById('show-verification');
    const backToRegisterBtn = document.getElementById('back-to-register');
    const showSuccessBtn = document.getElementById('show-success');

    // Setup navigation between different screens
    if (showRegisterBtn) {
        showRegisterBtn.addEventListener('click', function() {
            window.location.href = '新規登録.html';
        });
    }
    
    if (showLoginBtn) {
        showLoginBtn.addEventListener('click', function() {
            window.location.href = 'ログイン.html';
        });
    }
    
    if (backToLoginBtn) {
        backToLoginBtn.addEventListener('click', function() {
            window.location.href = 'ログイン.html';
        });
    }
    
    if (showVerificationBtn) {
        showVerificationBtn.addEventListener('click', function() {
            window.location.href = '認証コード.html';
        });
    }
    
    if (backToRegisterBtn) {
        backToRegisterBtn.addEventListener('click', function() {
            window.location.href = '新規登録.html';
        });
    }
    
    if (showSuccessBtn) {
        showSuccessBtn.addEventListener('click', function() {
            window.location.href = '登録完了.html';
        });
    }
}

// Verification code input handling - only setup if on verification page
function setupVerificationCodeInputs() {
    const codeInputs = document.querySelectorAll('.code-input');
    if (codeInputs.length === 0) return;
    
    codeInputs.forEach(function(input) {
        input.addEventListener('input', function() {
            if (this.value.length === 1) {
                const nextIndex = parseInt(this.getAttribute('data-index')) + 1;
                if (nextIndex <= 6) {
                    const nextInput = document.querySelector(`.code-input[data-index="${nextIndex}"]`);
                    nextInput.focus();
                    codeInputs.forEach(inp => inp.classList.remove('active'));
                    nextInput.classList.add('active');
                }
            }
        });
        
        input.addEventListener('keydown', function(e) {
            if (e.key === 'Backspace' && this.value.length === 0) {
                const prevIndex = parseInt(this.getAttribute('data-index')) - 1;
                if (prevIndex >= 1) {
                    const prevInput = document.querySelector(`.code-input[data-index="${prevIndex}"]`);
                    prevInput.focus();
                    prevInput.value = '';
                    codeInputs.forEach(inp => inp.classList.remove('active'));
                    prevInput.classList.add('active');
                }
            }
        });
        
        input.addEventListener('focus', function() {
            codeInputs.forEach(inp => inp.classList.remove('active'));
            this.classList.add('active');
        });
    });
    
    // Timer for resend code
    startResendTimer();
}

function startResendTimer() {
    const timerElement = document.getElementById('timer');
    if (!timerElement) return;
    
    let timeLeft = 59;
    const timerInterval = setInterval(function() {
        if (timeLeft <= 0) {
            clearInterval(timerInterval);
            timerElement.style.display = 'none';
        } else {
            const currentLanguage = document.documentElement.lang === 'en' ? 'en' : 'ja';
            timerElement.textContent = currentLanguage === 'ja' ? 
                `(${timeLeft}秒)` : `(${timeLeft}s)`;
            timeLeft--;
        }
    }, 1000);
}