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

app.get('/checkout', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/checkout.html'));
});

// Add a product to the cart for the logged-in user
app.post('/api/checkout', (req, res) => {
    const userId = req.session.userId;
    const { iban, cvc, expiry, owner } = req.body;

    if (!userId) {
        return res.status(401).send('User not authenticated');
    }

    const fetchCartQuery = 'SELECT cart_id, products FROM carts WHERE user_id = ?';
    connection.query(fetchCartQuery, [userId], (err, results) => {
        if (err) {
            console.error('Error fetching cart:', err);
            return res.status(500).send('Server error');
        }

        if (results.length === 0) {
            return res.status(400).send('Cart is empty');
        }

        const { cart_id, products } = results[0];
        let productList;

        try {
            productList = JSON.parse(products) || [];
        } catch (parseError) {
            console.error('Error parsing products JSON:', parseError);
            return res.status(500).send('Server error');
        }

        if (productList.length === 0) {
            return res.status(400).send('Cart is empty');
        }

        const fetchProductsQuery = `
            SELECT id AS product_id, value AS price 
            FROM products 
            WHERE id IN (${productList.map(p => p.product_id).join(',')})
        `;
        connection.query(fetchProductsQuery, (err, productDetails) => {
            if (err) {
                console.error('Error fetching product details:', err);
                return res.status(500).send('Server error');
            }

            if (!productDetails || productDetails.length === 0) {
                console.warn('No product details found');
                return res.status(400).send('Cart contains invalid products');
            }

            const totalAmount = productList.reduce((sum, item) => {
                const product = productDetails.find(p => p.product_id === item.product_id);
                return sum + (product ? product.price * item.quantity : 0);
            }, 0);

            const createOrderQuery = 'INSERT INTO orders (user_id, cart_id, total_amount) VALUES (?, ?, ?)';
            connection.query(createOrderQuery, [userId, cart_id, totalAmount], (err) => {
                if (err) {
                    console.error('Error creating order:', err);
                    return res.status(500).send('Server error');
                }

                const clearCartQuery = 'DELETE FROM carts WHERE user_id = ?';
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

// Fetch cart items for the logged-in user
app.get('/api/cart', (req, res) => {
    const userId = req.session.userId;

    if (!userId) {
        return res.status(401).json({ message: 'User not authenticated' });
    }

    const fetchCartQuery = 'SELECT products FROM carts WHERE user_id = ?';
    connection.query(fetchCartQuery, [userId], (err, results) => {
        if (err) {
            console.error('Error fetching cart:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        if (results.length === 0 || !results[0].products) {
            return res.json([]); // Return an empty array for an empty cart
        }

        let products;
        try {
            products = JSON.parse(results[0].products) || [];
        } catch (parseError) {
            console.error('Error parsing products JSON:', parseError);
            return res.status(500).json({ message: 'Server error' });
        }

        res.json(products);
    });
});

app.delete('/api/cart/:productId', (req, res) => {
    const productId = parseInt(req.params.productId, 10); // Ensure productId is a number
    const userId = req.session.userId;

    if (!userId) {
        return res.status(401).send('User not authenticated');
    }

    const fetchCartQuery = 'SELECT cart_id, products FROM carts WHERE user_id = ? LIMIT 1';
    connection.query(fetchCartQuery, [userId], (err, results) => {
        if (err) {
            console.error('Error fetching cart:', err);
            return res.status(500).send('Server error');
        }

        if (results.length === 0) {
            return res.status(404).send('Cart not found');
        }

        let { cart_id, products } = results[0];
        try {
            products = JSON.parse(products) || [];
        } catch (parseError) {
            console.error('Error parsing products JSON:', parseError);
            return res.status(500).send('Server error');
        }

        // Filter out the product to be removed
        const updatedProducts = products.filter(p => p.product_id !== productId);

        if (updatedProducts.length === 0) {
            // Delete the entire cart row if no products remain
            const deleteCartQuery = 'DELETE FROM carts WHERE cart_id = ?';
            connection.query(deleteCartQuery, [cart_id], (err) => {
                if (err) {
                    console.error('Error deleting cart:', err);
                    return res.status(500).send('Server error');
                }
                res.status(200).send('Cart deleted as it became empty');
            });
        } else {
            // Update the cart with the remaining products
            const updateCartQuery = 'UPDATE carts SET products = ? WHERE cart_id = ?';
            connection.query(updateCartQuery, [JSON.stringify(updatedProducts), cart_id], (err) => {
                if (err) {
                    console.error('Error updating cart:', err);
                    return res.status(500).send('Server error');
                }
                res.status(200).send('Product removed from cart');
            });
        }
    });
});

app.patch('/api/cart/:productId/quantity', (req, res) => {
    const productId = parseInt(req.params.productId, 10); // Ensure productId is a number
    const userId = req.session.userId;
    const { delta } = req.body;

    if (!userId) {
        return res.status(401).send('User not authenticated');
    }

    const fetchCartQuery = 'SELECT products FROM carts WHERE user_id = ?';
    connection.query(fetchCartQuery, [userId], (err, results) => {
        if (err) {
            console.error('Error fetching cart:', err);
            return res.status(500).send('Server error');
        }

        if (results.length === 0) {
            return res.status(404).send('Cart not found');
        }

        let products = [];
        try {
            products = JSON.parse(results[0].products);
        } catch (parseError) {
            console.error('Error parsing products JSON:', parseError);
            return res.status(500).send('Server error');
        }

        // Find and update the product quantity
        const product = products.find(p => p.product_id === productId);
        if (product) {
            product.quantity = Math.max(product.quantity + delta, 0); // Ensure non-negative quantity
        } else {
            return res.status(404).send('Product not found in cart');
        }

        const updateCartQuery = 'UPDATE carts SET products = ? WHERE user_id = ?';
        connection.query(updateCartQuery, [JSON.stringify(products), userId], (err) => {
            if (err) {
                console.error('Error updating cart:', err);
                return res.status(500).send('Server error');
            }

            res.status(200).send('Quantity updated successfully');
        });
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

app.post('/api/cart', (req, res) => {
    const { productId } = req.body;
    const userId = req.session.userId;

    if (!userId) {
        return res.status(401).json({ message: 'User not authenticated' });
    }

    const fetchCartQuery = 'SELECT cart_id, products FROM carts WHERE user_id = ? LIMIT 1';
    connection.query(fetchCartQuery, [userId], (err, results) => {
        if (err) {
            console.error('Error fetching cart:', err);
            return res.status(500).json({ message: 'Server error' });
        }

        let products = [];
        let cartId;

        if (results.length > 0) {
            cartId = results[0].cart_id;
            try {
                products = JSON.parse(results[0].products) || [];
            } catch (parseError) {
                console.error('Error parsing products JSON:', parseError);
                products = [];
            }
        }

        const existingProduct = products.find(p => p.product_id === productId);
        if (existingProduct) {
            existingProduct.quantity += 1;
        } else {
            products.push({ product_id: productId, quantity: 1 });
        }

        if (cartId) {
            // Update existing cart
            const updateCartQuery = 'UPDATE carts SET products = ? WHERE cart_id = ?';
            connection.query(updateCartQuery, [JSON.stringify(products), cartId], (err) => {
                if (err) {
                    console.error('Error updating cart:', err);
                    return res.status(500).json({ message: 'Server error' });
                }
                res.status(200).json({ message: 'Product added to existing cart' });
            });
        } else {
            // Create a new cart
            const createCartQuery = 'INSERT INTO carts (user_id, products) VALUES (?, ?)';
            connection.query(createCartQuery, [userId, JSON.stringify(products)], (err) => {
                if (err) {
                    console.error('Error creating new cart:', err);
                    return res.status(500).json({ message: 'Server error' });
                }
                res.status(201).json({ message: 'Product added to new cart' });
            });
        }
    });
});

// Serve the home page for the root URL
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/EshopPage.html'));
});

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
