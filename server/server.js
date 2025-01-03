const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const path = require('path'); // For resolving file paths

const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');
const session = require('express-session');

const app = express();
const port = 3000;

const SECRET_KEY = 'mYA3eyYD0R-dI420-81COf7';

// Enable CORS for client-side requests
app.use(cors());

// Serve static files from the 'public' folder
app.use(express.static(path.join(__dirname, '../public')));

app.use(bodyParser.json());
app.use(session({
    secret: SECRET_KEY,
    resave: false,
    saveUninitialized: true,
}));

// Database connection
const connection = mysql.createConnection({
    host: 'localhost',
    user: 'techhub',
    password: '!@#123Abc',
    database: 'TechGearHub'
});

connection.connect((err) => {
    if (err) throw err;
    console.log('Connected to MySQL!');
});

// User registration
app.post('/api/register', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).send('Username and password are required');
    }

    bcrypt.hash(password, 10, (err, hash) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Server error');
        }

        const query = 'INSERT INTO users (username, password) VALUES (?, ?)';
        connection.query(query, [username, hash], (err) => {
            if (err) {
                console.error(err);
                return res.status(500).send('Server error');
            }
            res.status(201).send('User registered successfully');
        });
    });
});

// User login
app.post('/api/login', (req, res) => {
    const { username, password } = req.body;

    const query = 'SELECT * FROM users WHERE username = ?';
    connection.query(query, [username], (err, results) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Server error');
        }

        if (results.length === 0) {
            return res.status(401).send('Invalid username or password');
        }

        const user = results[0];
        bcrypt.compare(password, user.password, (err, isMatch) => {
            if (err) {
                console.error(err);
                return res.status(500).send('Server error');
            }

            if (!isMatch) {
                return res.status(401).send('Invalid username or password');
            }

            req.session.userId = user.id;
            res.status(200).send('Login successful');
        });
    });
});

app.post('/api/register', (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).send('Username and password are required');
    }

    bcrypt.hash(password, 10, (err, hash) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Server error');
        }

        const query = 'INSERT INTO users (username, password) VALUES (?, ?)';
        connection.query(query, [username, hash], (err) => {
            if (err) {
                if (err.code === 'ER_DUP_ENTRY') {
                    return res.status(400).send('Username already exists');
                }
                console.error(err);
                return res.status(500).send('Server error');
            }
            res.status(201).send('User registered successfully');
        });
    });
});

// Endpoint to get the logged-in user's info
app.get('/api/user', (req, res) => {
    if (req.session.userId) {
        const query = 'SELECT username FROM users WHERE id = ?';
        connection.query(query, [req.session.userId], (err, results) => {
            if (err) {
                console.error(err);
                res.status(500).send('Server error');
            } else if (results.length > 0) {
                res.json({ username: results[0].username });
            } else {
                res.status(404).send('User not found');
            }
        });
    } else {
        res.status(401).send('Not authenticated');
    }
});

// Logout endpoint
app.post('/api/logout', (req, res) => {
    req.session.destroy((err) => {
        if (err) {
            console.error(err);
            res.status(500).send('Server error');
        } else {
            res.status(200).send('Logged out successfully');
        }
    });
});


// Check authentication
function isAuthenticated(req, res, next) {
    if (req.session.userId) {
        next();
    } else {
        res.status(401).send('You need to log in first');
    }
}

// Add to cart (authenticated users only)
app.post('/api/cart', isAuthenticated, (req, res) => {
    const { productId } = req.body;

    const query = 'UPDATE products SET cart = true WHERE id = ?';
    connection.query(query, [productId], (err) => {
        if (err) {
            console.error(err);
            return res.status(500).send('Server error');
        }
        res.status(200).send('Product added to cart');
    });
});

// Logout
app.post('/api/logout', (req, res) => {
    req.session.destroy();
    res.status(200).send('Logged out successfully');
});

// Endpoint to fetch products by category
app.get('/api/products', (req, res) => {
    const category = req.query.category;

    const query = category
        ? 'SELECT * FROM products WHERE category = ?'
        : 'SELECT * FROM products';

    connection.query(query, category ? [category] : [], (err, results) => {
        if (err) {
            console.error(err);
            res.status(500).send('Server Error');
        } else {
            res.json(results);
        }
    });
});

app.get('/checkout', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/checkout.html'));
});

// Serve category pages dynamically
app.get('/:category', (req, res) => {
    const category = req.params.category;

    // Check if the category matches known categories
    const validCategories = ['cpu', 'ram', 'storage', 'gpu', 'home'];
    if (validCategories.includes(category)) {
        res.sendFile(path.join(__dirname, '../public/EshopPage.html'));
    } else {
        res.status(404).send('Page Not Found');
    }
});

// Serve the home page for the root URL
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/EshopPage.html'));
});

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
