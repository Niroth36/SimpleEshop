// Example products data
const products = [
    { id: 1, title: "Intel Core i9-13900K", description: "High-performance CPU", image: "cpu1.jpg", value: 599, category: "cpu" },
    { id: 2, title: "Corsair Vengeance 16GB RAM", description: "Reliable and fast RAM", image: "ram1.jpg", value: 89, category: "ram" },
    { id: 3, title: "Samsung 970 EVO SSD", description: "High-speed storage", image: "storage1.jpg", value: 109, category: "storage" },
    { id: 4, title: "NVIDIA GeForce RTX 3080", description: "Top-tier GPU", image: "gpu1.jpg", value: 699, category: "gpu" }
];

// Function to render products
function renderProducts(category) {
    const productContainer = document.getElementById("product-container");
    productContainer.innerHTML = ""; // Clear previous content

    const filteredProducts = products.filter(product => product.category === category || category === "home");

    filteredProducts.forEach(product => {
        const productDiv = document.createElement("div");
        productDiv.classList.add("product");

        productDiv.innerHTML = `
            <img src="${product.image}" alt="${product.title}" style="max-width: 150px; border-radius: 8px;">
            <div class="product-info">
                <h2>${product.title}</h2>
                <p>${product.description}</p>
                <p>Price: ${product.value}€</p>
                <button>Add to Cart</button>
            </div>
        `;
        productContainer.appendChild(productDiv);
    });
}

// Event listeners for navigation
document.querySelectorAll("nav a").forEach(navLink => {
    navLink.addEventListener("click", (e) => {
        e.preventDefault();
        const category = e.target.getAttribute("data-category");
        renderProducts(category);
    });
});

// Initial load
renderProducts("home");
