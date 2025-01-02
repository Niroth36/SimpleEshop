const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const path = require('path'); // For resolving file paths

const app = express();
const port = 3000;

// Enable CORS for client-side requests
app.use(cors());

// Serve static files from the 'public' folder
app.use(express.static(path.join(__dirname, '../public')));

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
