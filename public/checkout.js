// Load cart items from local storage
function loadCart() {
    const cartContainer = document.getElementById("cart-container");
    const cart = JSON.parse(localStorage.getItem("cart")) || [];

    if (cart.length === 0) {
        cartContainer.innerHTML = "<p>Your cart is empty.</p>";
        return;
    }

    cartContainer.innerHTML = ""; // Clear previous content

    cart.forEach((product, index) => {
        const productDiv = document.createElement("div");
        productDiv.classList.add("cart-item");

        productDiv.innerHTML = `
            <img src="${product.image}" alt="${product.title}" style="max-width: 100px; border-radius: 8px;">
            <div class="cart-item-info">
                <h2>${product.title}</h2>
                <p>${product.description}</p>
                <p>Price: ${product.value}€</p>
                <button class="remove-from-cart" data-index="${index}">Remove</button>
            </div>
        `;

        cartContainer.appendChild(productDiv);
    });

    // Attach event listeners to Remove buttons
    document.querySelectorAll(".remove-from-cart").forEach(button => {
        button.addEventListener("click", (e) => {
            const index = e.target.getAttribute("data-index");
            removeFromCart(index);
        });
    });
}

// Remove a product from the cart
function removeFromCart(index) {
    const cart = JSON.parse(localStorage.getItem("cart")) || [];
    cart.splice(index, 1); // Remove the item at the specified index
    localStorage.setItem("cart", JSON.stringify(cart)); // Save the updated cart
    loadCart(); // Re-render the cart
}

// Initialize the cart
loadCart();

// Event listener for Proceed to Payment button
document.getElementById("proceed-to-payment").addEventListener("click", () => {
    alert("Proceeding to payment..."); // Replace with actual payment processing logic
});
