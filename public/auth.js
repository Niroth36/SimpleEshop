document.addEventListener('DOMContentLoaded', () => {
    // Handle registration
    document.getElementById('register-form').addEventListener('submit', (e) => {
        e.preventDefault();

        const username = document.getElementById('register-username').value;
        const password = document.getElementById('register-password').value;

        fetch('/api/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password }),
        })
            .then(response => response.text())
            .then(message => {
                const registerMessage = document.getElementById('register-message');
                registerMessage.textContent = message;

                if (message === 'User registered successfully') {
                    alert('Registration successful! You can now log in.');
                    document.getElementById('register-username').value = '';
                    document.getElementById('register-password').value = '';
                }
            })
            .catch(err => console.error('Error during registration:', err));
    });

    // Handle login
    document.getElementById('login-form').addEventListener('submit', (e) => {
        e.preventDefault();

        const username = document.getElementById('login-username').value;
        const password = document.getElementById('login-password').value;

        fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, password }),
        })
            .then(response => response.text())
            .then(message => {
                const loginMessage = document.getElementById('login-message');
                loginMessage.textContent = message;

                if (message === 'Login successful') {
                    alert('Login successful!');
                    window.location.href = '/';
                }
            })
            .catch(err => console.error('Error during login:', err));
    });
});
