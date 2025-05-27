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

// Input validation functions
function validateIBAN(iban) {
    // Remove spaces and convert to uppercase
    const cleanIban = iban.replace(/\s/g, '').toUpperCase();
    // Check if it's exactly 16 digits (for simplified validation)
    return /^\d{16}$/.test(cleanIban);
}

function validateCVC(cvc) {
    // Check if it's exactly 3 digits
    return /^\d{3}$/.test(cvc);
}

function validateExpiry(expiry) {
    // Check MM/YY format
    if (!/^\d{2}\/\d{2}$/.test(expiry)) {
        return false;
    }
    
    const [month, year] = expiry.split('/').map(num => parseInt(num));
    const currentDate = new Date();
    const currentYear = currentDate.getFullYear() % 100; // Get last 2 digits
    const currentMonth = currentDate.getMonth() + 1;
    
    // Validate month (01-12)
    if (month < 1 || month > 12) {
        return false;
    }
    
    // Check if expiry date is in the future
    if (year < currentYear || (year === currentYear && month < currentMonth)) {
        return false;
    }
    
    return true;
}

function validateOwner(owner) {
    // Only alphanumeric characters and spaces, at least 2 characters
    return /^[a-zA-Z\s]{2,}$/.test(owner.trim());
}

// Input formatters
function formatIBAN(input) {
    // Remove all non-digits and limit to 16 characters
    let value = input.value.replace(/\D/g, '').substring(0, 16);
    // Add spaces every 4 digits for readability
    value = value.replace(/(\d{4})(?=\d)/g, '$1 ');
    input.value = value;
}

function formatCVC(input) {
    // Remove all non-digits and limit to 3 characters
    input.value = input.value.replace(/\D/g, '').substring(0, 3);
}

function formatExpiry(input) {
    // Remove all non-digits
    let value = input.value.replace(/\D/g, '');
    
    // Add slash after 2 digits and limit to MM/YY format
    if (value.length >= 2) {
        value = value.substring(0, 2) + '/' + value.substring(2, 4);
    }
    
    input.value = value;
}

function formatOwner(input) {
    // Remove non-alphabetic characters except spaces
    input.value = input.value.replace(/[^a-zA-Z\s]/g, '');
}

// Add event listeners for real-time formatting
document.addEventListener('DOMContentLoaded', function() {
    const ibanInput = document.getElementById('iban');
    const cvcInput = document.getElementById('cvc');
    const expiryInput = document.getElementById('expiry');
    const ownerInput = document.getElementById('owner');

    if (ibanInput) {
        ibanInput.addEventListener('input', function() {
            formatIBAN(this);
        });
        ibanInput.setAttribute('placeholder', '1234 5678 9012 3456');
        ibanInput.setAttribute('maxlength', '19'); // 16 digits + 3 spaces
    }

    if (cvcInput) {
        cvcInput.addEventListener('input', function() {
            formatCVC(this);
        });
        cvcInput.setAttribute('placeholder', '123');
        cvcInput.setAttribute('maxlength', '3');
    }

    if (expiryInput) {
        expiryInput.addEventListener('input', function() {
            formatExpiry(this);
        });
        expiryInput.setAttribute('placeholder', 'MM/YY');
        expiryInput.setAttribute('maxlength', '5');
    }

    if (ownerInput) {
        ownerInput.addEventListener('input', function() {
            formatOwner(this);
        });
        ownerInput.setAttribute('placeholder', 'John Doe');
    }
});

// Handle the checkout form submission
const checkoutForm = document.getElementById('checkout-form');
if (checkoutForm) {
    checkoutForm.addEventListener('submit', (e) => {
        e.preventDefault();

        const iban = document.getElementById('iban').value;
        const cvc = document.getElementById('cvc').value;
        const expiry = document.getElementById('expiry').value;
        const owner = document.getElementById('owner').value;

        // Basic required field check
        if (!iban || !cvc || !expiry || !owner) {
            alert('Please fill in all the fields.');
            return;
        }

        // Detailed validation
        const errors = [];

        if (!validateIBAN(iban)) {
            errors.push('IBAN must be exactly 16 digits');
        }

        if (!validateCVC(cvc)) {
            errors.push('CVC must be exactly 3 digits');
        }

        if (!validateExpiry(expiry)) {
            errors.push('Expiry date must be in MM/YY format and not be expired');
        }

        if (!validateOwner(owner)) {
            errors.push('Owner name must contain only letters and spaces (minimum 2 characters)');
        }

        if (errors.length > 0) {
            alert('Please fix the following errors:\n• ' + errors.join('\n• '));
            return;
        }

        // Clean IBAN for submission (remove spaces)
        const cleanIban = iban.replace(/\s/g, '');

        fetch('/api/checkout', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                iban: cleanIban, 
                cvc, 
                expiry, 
                owner: owner.trim() 
            }),
        })
            .then(response => {
                if (response.ok) {
                    alert('Order placed successfully!');
                    loadCheckoutSummary(); // Reload the summary without clearing the cart
                    // Clear the form
                    checkoutForm.reset();
                } else {
                    response.text().then(message => alert(`Failed to complete the order: ${message}`));
                }
            })
            .catch(err => {
                console.error('Error completing order:', err);
                alert('Error completing order. Please try again.');
            });
    });
}

// Handle clear cart button click
const clearCartButton = document.getElementById('clear-cart');
if (clearCartButton) {
    clearCartButton.addEventListener('click', () => {
        if (confirm('Are you sure you want to clear the cart?')) {
            fetch('/api/cart/clear', { method: 'DELETE' })
                .then(response => {
                    if (response.ok) {
                        alert('Cart cleared successfully!');
                        loadCheckoutSummary(); // Reload the summary to show an empty cart
                    } else {
                        response.text().then(message => alert(`Failed to clear cart: ${message}`));
                    }
                })
                .catch(err => {
                    console.error('Error clearing cart:', err);
                    alert('Error clearing cart. Please try again.');
                });
        }
    });
}

// Initialize the page
window.addEventListener('load', loadCheckoutSummary);