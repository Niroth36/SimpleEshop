// Load cart items from the server
function loadCart() {
    fetch('/api/cart')
        .then(response => {
            if (response.status === 401) {
                document.getElementById('cart-container').innerHTML = '<p>You need to log in to view your cart.</p>';
                return [];
            }
            return response.json();
        })
        .then(cartItems => {
            const cartContainer = document.getElementById('cart-container');

            if (cartItems.length === 0) {
                cartContainer.innerHTML = '<p>Your cart is empty.</p>';
                return;
            }

            cartContainer.innerHTML = ''; // Clear previous content

            cartItems.forEach(item => {
                const itemDiv = document.createElement('div');
                itemDiv.classList.add('cart-item');

                itemDiv.innerHTML = `
                    <span class="cart-title">${item.title}</span>
                    <button class="quantity-btn minus-btn" data-id="${item.product_id}">-</button>
                    <span class="cart-quantity">${item.quantity}</span>
                    <button class="quantity-btn plus-btn" data-id="${item.product_id}">+</button>
                    <button class="remove-btn" data-id="${item.product_id}">Remove</button>
                `;

                cartContainer.appendChild(itemDiv);
            });

            // Attach event listeners to buttons
            attachEventListeners();
        })
        .catch(err => console.error('Error fetching cart items:', err));
}

// Attach event listeners to buttons
function attachEventListeners() {
    document.querySelectorAll('.remove-btn').forEach(button => {
        button.addEventListener('click', e => {
            const productId = e.target.dataset.id;
            removeFromCart(productId);
        });
    });

    document.querySelectorAll('.plus-btn').forEach(button => {
        button.addEventListener('click', e => {
            const productId = e.target.dataset.id;
            adjustQuantity(productId, 1);
        });
    });

    document.querySelectorAll('.minus-btn').forEach(button => {
        button.addEventListener('click', e => {
            const productId = e.target.dataset.id;
            adjustQuantity(productId, -1);
        });
    });
}

// Remove a product from the cart
function removeFromCart(productId) {
    fetch(`/api/cart/${productId}`, { method: 'DELETE' })
        .then(response => {
            if (response.ok) {
                loadCart(); // Reload the cart
            } else {
                alert('Failed to remove product from cart');
            }
        })
        .catch(err => console.error('Error removing product:', err));
}

// Adjust the quantity of a product in the cart
function adjustQuantity(productId, delta) {
    fetch(`/api/cart/${productId}/quantity`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ delta }),
    })
        .then(response => {
            if (response.ok) {
                loadCart(); // Reload the cart
            } else {
                alert('Failed to update product quantity');
            }
        })
        .catch(err => console.error('Error adjusting quantity:', err));
}

// Initialize the cart
window.addEventListener('load', loadCart);
