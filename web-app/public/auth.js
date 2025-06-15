document.addEventListener('DOMContentLoaded', () => {
    // Handle registration
    document.getElementById('register-form').addEventListener('submit', (e) => {
        e.preventDefault();

        const username = document.getElementById('register-username').value;
        const email = document.getElementById('register-email').value; // Get email value
        const password = document.getElementById('register-password').value;

        fetch('/api/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ username, email, password }), // Send email
        })
            .then(response => {
                if (!response.ok) {
                    return response.text().then(text => Promise.reject(text));
                }
                return response.text();
            })
            .then(message => {
                const registerMessage = document.getElementById('register-message');
                registerMessage.textContent = message;

                if (message === 'User registered successfully') {
                    alert('Registration successful! You can now log in.');
                    document.getElementById('register-username').value = '';
                    document.getElementById('register-email').value = ''; // Clear email
                    document.getElementById('register-password').value = '';
                }
            })
            .catch(err => {
                console.error('Error during registration:', err);
                const registerMessage = document.getElementById('register-message');
                registerMessage.textContent = err || 'Registration failed.';
                registerMessage.style.color = 'red';
            });
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
            .then(response => {
                if (!response.ok) {
                    return response.text().then(text => Promise.reject(text));
                }
                return response.text();
            })
            .then(message => {
                const loginMessage = document.getElementById('login-message');
                loginMessage.textContent = message;

                if (message === 'Login successful') {
                    alert('Login successful!');
                    window.location.href = '/';
                }
            })
            .catch(err => {
                console.error('Error during login:', err);
                const loginMessage = document.getElementById('login-message');
                loginMessage.textContent = err || 'Login failed.';
                loginMessage.style.color = 'red';
            });
    });
});