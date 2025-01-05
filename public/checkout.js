// Load the checkout summary
function loadCheckoutSummary() {
    fetch('/api/cart')
        .then(response => response.json())
        .then(cartItems => {
            const summaryContainer = document.getElementById('checkout-summary');
            let totalAmount = 0;

            summaryContainer.innerHTML = '<h2>Order Summary</h2>';
            cartItems.forEach((item, index) => {
                const itemDiv = document.createElement('div');
                const itemTotal = item.price * item.quantity;
                totalAmount += itemTotal;

                itemDiv.textContent = `${index + 1}. ${item.title} - ${item.quantity} x ${item.price}€ = ${itemTotal.toFixed(2)}€`;
                summaryContainer.appendChild(itemDiv);
            });

            const totalDiv = document.createElement('div');
            totalDiv.innerHTML = `<strong>Total: ${totalAmount.toFixed(2)}€</strong>`;
            summaryContainer.appendChild(totalDiv);
        })
        .catch(err => console.error('Error fetching cart items:', err));
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
                    alert('Failed to complete the order');
                }
            })
            .catch(err => console.error('Error completing order:', err));
    });
} else {
    console.error('Checkout form not found');
}

// Initialize the page
window.addEventListener('load', loadCheckoutSummary);
