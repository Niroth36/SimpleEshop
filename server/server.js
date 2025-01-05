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

app.get('/cart', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/cart.html'));
});

// Add a product to the cart for the logged-in user
app.post('/api/cart', (req, res) => {
    const { productId } = req.body;
    const userId = req.session.userId;

    if (!userId) {
        return res.status(401).send('User not authenticated');
    }

    // Check if the product is already in the cart
    const checkQuery = 'SELECT * FROM cart_items WHERE user_id = ? AND product_id = ?';
    connection.query(checkQuery, [userId, productId], (err, results) => {
        if (err) {
            console.error('Error checking cart items:', err);
            return res.status(500).send('Server error');
        }

        if (results.length > 0) {
            // Update the quantity if the product is already in the cart
            const updateQuery = 'UPDATE cart_items SET quantity = quantity + 1 WHERE user_id = ? AND product_id = ?';
            connection.query(updateQuery, [userId, productId], (err) => {
                if (err) {
                    console.error('Error updating cart item:', err);
                    return res.status(500).send('Server error');
                }
                res.status(200).send('Product quantity updated in cart');
            });
        } else {
            // Insert the product into the cart
            const insertQuery = 'INSERT INTO cart_items (user_id, product_id, quantity) VALUES (?, ?, 1)';
            connection.query(insertQuery, [userId, productId], (err) => {
                if (err) {
                    console.error('Error inserting cart item:', err);
                    return res.status(500).send('Server error');
                }
                res.status(200).send('Product added to cart');
            });
        }
    });
});

// Fetch cart items for the logged-in user
app.get('/api/cart', (req, res) => {
    const userId = req.session.userId;

    if (!userId) {
        return res.status(401).send('User not authenticated');
    }

    const query = `
        SELECT 
            p.id AS product_id, 
            p.title, 
            p.description, 
            p.image, 
            p.value, 
            c.quantity 
        FROM cart_items c
        JOIN products p ON c.product_id = p.id
        WHERE c.user_id = ?
    `;

    connection.query(query, [userId], (err, results) => {
        if (err) {
            console.error('Error fetching cart items:', err);
            return res.status(500).send('Server error');
        }
        res.json(results);
    });
});

app.delete('/api/cart/:productId', (req, res) => {
    const productId = req.params.productId;
    const userId = req.session.userId;

    if (!userId) {
        return res.status(401).send('User not authenticated');
    }

    const deleteQuery = 'DELETE FROM cart_items WHERE user_id = ? AND product_id = ?';
    connection.query(deleteQuery, [userId, productId], (err) => {
        if (err) {
            console.error('Error deleting cart item:', err);
            return res.status(500).send('Server error');
        }
        res.status(200).send('Product removed from cart');
    });
});

app.patch('/api/cart/:productId/quantity', (req, res) => {
    const productId = req.params.productId;
    const userId = req.session.userId;
    const { delta } = req.body;

    if (!userId) {
        return res.status(401).send('User not authenticated');
    }

    const updateQuery = `
        UPDATE cart_items 
        SET quantity = GREATEST(quantity + ?, 0) 
        WHERE user_id = ? AND product_id = ?
    `;
    connection.query(updateQuery, [delta, userId, productId], (err) => {
        if (err) {
            console.error('Error updating quantity:', err);
            return res.status(500).send('Server error');
        }
        res.status(200).send('Quantity updated');
    });
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

app.post('/api/checkout', (req, res) => {
    const userId = req.session.userId;
    const { iban, cvc, expiry, owner } = req.body;

    if (!userId) {
        return res.status(401).send('User not authenticated');
    }

    // Validate card details (basic example, expand as needed)
    if (!iban || !cvc || !expiry || !owner) {
        return res.status(400).send('All card details are required');
    }

    // Fetch the cart items
    const cartQuery = `
        SELECT c.product_id, c.quantity, p.value AS price 
        FROM cart_items c
        JOIN products p ON c.product_id = p.id
        WHERE c.user_id = ?
    `;

    connection.query(cartQuery, [userId], (err, cartItems) => {
        if (err) {
            console.error('Error fetching cart items:', err);
            return res.status(500).send('Server error');
        }

        if (cartItems.length === 0) {
            return res.status(400).send('Cart is empty');
        }

        // Calculate total amount
        const totalAmount = cartItems.reduce((sum, item) => sum + item.price * item.quantity, 0);

        // Insert into orders table
        const orderQuery = 'INSERT INTO orders (user_id, total_amount) VALUES (?, ?)';
        connection.query(orderQuery, [userId, totalAmount], (err, result) => {
            if (err) {
                console.error('Error creating order:', err);
                return res.status(500).send('Server error');
            }

            const orderId = result.insertId;

            // Insert into order_items table
            const orderItemsQuery = `
                INSERT INTO order_items (order_id, product_id, quantity, price)
                VALUES ?
            `;
            const orderItemsValues = cartItems.map(item => [
                orderId,
                item.product_id,
                item.quantity,
                item.price,
            ]);

            connection.query(orderItemsQuery, [orderItemsValues], (err) => {
                if (err) {
                    console.error('Error adding order items:', err);
                    return res.status(500).send('Server error');
                }

                // Clear the cart
                const clearCartQuery = 'DELETE FROM cart_items WHERE user_id = ?';
                connection.query(clearCartQuery, [userId], (err) => {
                    if (err) {
                        console.error('Error clearing cart:', err);
                        return res.status(500).send('Server error');
                    }

                    res.status(200).send('Order completed successfully');
                });
            });
        });
    });
});

// Serve the home page for the root URL
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/EshopPage.html'));
});

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
