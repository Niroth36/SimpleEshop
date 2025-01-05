// Load the checkout summary
function loadCheckoutSummary() {
    fetch('/api/cart')
        .then(response => {
            if (response.ok) {
                return response.json();
            } else {
                throw new Error('Failed to fetch cart items');
            }
        })
        .then(cartItems => {
            const summaryContainer = document.getElementById('checkout-summary');
            let totalAmount = 0;

            // Clear previous content
            summaryContainer.innerHTML = '<h2>Order Summary</h2>';

            if (cartItems.length === 0) {
                summaryContainer.innerHTML += '<p>Your cart is empty.</p>';
                return;
            }

            cartItems.forEach((item, index) => {
                const itemDiv = document.createElement('div');
                const itemTotal = item.price * item.quantity;
                totalAmount += itemTotal;

                itemDiv.innerHTML = `
                    ${index + 1}. ${item.title} - ${item.quantity} x ${item.price.toFixed(2)}€ = ${(item.price * item.quantity).toFixed(2)}€
                `;
                summaryContainer.appendChild(itemDiv);
            });

            const totalDiv = document.createElement('div');
            totalDiv.innerHTML = `<strong>Total: ${totalAmount.toFixed(2)}€</strong>`;
            summaryContainer.appendChild(totalDiv);
        })
        .catch(err => {
            console.error('Error fetching cart items:', err);
            const summaryContainer = document.getElementById('checkout-summary');
            summaryContainer.innerHTML = '<p>Error loading cart items. Please try again later.</p>';
        });
}

// Handle the checkout form submission
const checkoutForm = document.getElementById('checkout-form');
if (checkoutForm) {
    checkoutForm.addEventListener('submit', (e) => {
        e.preventDefault();

        const iban = document.getElementById('iban').value;
        const cvc = document.getElementById('cvc').value;
        const expiry = document.getElementById('expiry').value;
        const owner = document.getElementById('owner').value;

        // Validate form fields
        if (!iban || !cvc || !expiry || !owner) {
            alert('Please fill in all the fields.');
            return;
        }

        fetch('/api/checkout', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ iban, cvc, expiry, owner }),
        })
            .then(response => {
                if (response.ok) {
                    alert('Order completed successfully!');
                    window.location.href = '/'; // Redirect to home page
                } else {
                    response.text().then(message => alert(`Failed to complete the order: ${message}`));
                }
            })
            .catch(err => console.error('Error completing order:', err));
    });
} else {
    console.error('Checkout form not found');
}

checkoutForm.addEventListener('submit', (e) => {
    e.preventDefault();

    const iban = document.getElementById('iban').value;
    const cvc = document.getElementById('cvc').value;
    const expiry = document.getElementById('expiry').value;
    const owner = document.getElementById('owner').value;

    // Validate form fields
    if (!iban || !cvc || !expiry || !owner) {
        alert('Please fill in all the fields.');
        return;
    }

    fetch('/api/checkout', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ iban, cvc, expiry, owner }),
    })
        .then(response => {
            if (response.ok) {
                alert('Order completed successfully!');
                window.location.href = '/'; // Redirect to home page
            } else {
                response.text().then(message => alert(`Failed to complete the order: ${message}`));
            }
        })
        .catch(err => console.error('Error completing order:', err));
});

// Initialize the page
window.addEventListener('load', loadCheckoutSummary);
