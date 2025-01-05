// Render content dynamically based on category
function renderContent(category) {
    const dynamicContent = document.getElementById("dynamic-content");
    dynamicContent.innerHTML = ""; // Clear previous content

    if (category === "home") {
        dynamicContent.innerHTML = `
            <div class="home-container">
                <img src="images/techgearhub.jpg" alt="Tech Hub Banner" class="home-banner">
                <p>
                    At Tech Hub, we bring you the best in computer parts and accessories. <br>
                    Whether you’re building a custom PC, upgrading your current setup, or looking for the latest tech innovations, we’ve got you covered. <br>
                    Explore our wide selection of processors, graphic cards, motherboards, and more, all at competitive prices. <br><br>
                    Tech Hub is your one-stop shop for quality, reliability, and performance. Let us help you power your next project!
                </p>
            </div>
        `;
    } else {
        fetchProducts(category).then(products => {
            if (products.length === 0) {
                dynamicContent.innerHTML = "<p>No products available in this category.</p>";
                return;
            }

            products.forEach(product => {
                const productDiv = document.createElement("div");
                productDiv.classList.add("product");

                productDiv.innerHTML = `
                    <br>
                    <br>
                    <img src="${product.image}" alt="${product.title}" style="max-width: 150px; border-radius: 8px;">
                    <div class="product-info">
                        <h2>${product.title}</h2>
                        <p>${product.description}</p>
                        <p>Price: ${product.value}€</p>
                        <button class="add-to-cart">Add to Cart</button>
                    </div>
                `;

                dynamicContent.appendChild(productDiv);

                const addToCartButton = productDiv.querySelector('.add-to-cart');
                addToCartButton.addEventListener('click', () => {
                    addToCart(product);
                });
            });
        });
    }
}

// Fetch products from the API based on the category
function fetchProducts(category) {
    const apiUrl = `/api/products?category=${category}`;
    return fetch(apiUrl)
        .then(response => response.json())
        .catch(err => {
            console.error("Error fetching products:", err);
            return [];
        });
}

// Add a product to the cart
function addToCart(product) {
    console.log('Adding product to cart:', product); // Debug log

    fetch('/api/cart', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ productId: product.id }),
    })
        .then(response => {
            if (response.status === 401) {
                alert('You need to log in to add products to the cart');
                window.location.href = '/auth.html';
            } else if (response.ok) {
                alert('Product added to cart');
                updateCartCount(); // Update cart count after adding a product
            } else {
                return response.json().then(err => {
                    console.error('Error adding product:', err);
                    alert(err.message || 'Failed to add product to cart');
                });
            }
        })
        .catch(err => console.error('Error adding product to cart:', err));
}

// Update the navigation bar based on authentication status
function updateNavBar() {
    fetch('/api/user')
        .then(response => {
            if (response.status === 401) {
                // Not authenticated: Show Login button, hide Logout and Username
                document.getElementById('login-button').style.display = 'inline-block';
                document.getElementById('logout-button').style.display = 'none';
                document.getElementById('username-display').textContent = '';
            } else {
                // Authenticated: Show Logout and Username, hide Login button
                response.json().then(data => {
                    document.getElementById('username-display').textContent = `Hello, ${data.username}`;
                    document.getElementById('logout-button').style.display = 'inline-block';
                    document.getElementById('login-button').style.display = 'none';
                });
            }
        })
        .catch(err => console.error('Error fetching user status:', err));
}

// Handle logout
function handleLogout() {
    fetch('/api/logout', { method: 'POST' })
        .then(response => {
            if (response.ok) {
                alert('You have been logged out.');
                window.location.reload(); // Reload the page to update UI
            }
        })
        .catch(err => console.error('Error logging out:', err));
}

// Attach event listeners to buttons
function initializeNavBar() {
    const logoutButton = document.getElementById('logout-button');
    const loginButton = document.getElementById('login-button');

    if (logoutButton) {
        logoutButton.addEventListener('click', handleLogout);
    }

    if (loginButton) {
        loginButton.addEventListener('click', () => {
            window.location.href = '/auth.html'; // Redirect to the auth page
        });
    }
}

// Update the cart count in the navigation bar
function updateCartCount() {
    fetch('/api/cart')
        .then(response => {
            if (response.status === 401) {
                // User not authenticated; cart count is 0
                document.getElementById('cart-count').textContent = '0';
                return [];
            }
            return response.json();
        })
        .then(cartItems => {
            // Update the cart count with the number of lines (distinct products)
            document.getElementById('cart-count').textContent = cartItems.length;
        })
        .catch(err => console.error('Error fetching cart items:', err));
}


// Handle page load to render the appropriate content
function handlePageLoad() {
    const path = window.location.pathname.substring(1); // Get the path without "/"
    const category = path || "home"; // Default to 'home' if no category
    renderContent(category);
}

// Handle browser navigation (back/forward buttons)
window.addEventListener("popstate", handlePageLoad);

// Initialize everything on page load
window.addEventListener("load", () => {
    updateNavBar();
    initializeNavBar();
    updateCartCount();
    handlePageLoad();
});
