// Fetch products based on the current URL
function fetchAndRenderProducts(category = 'home') {
    const apiUrl = `/api/products?category=${category}`;

    fetch(apiUrl)
        .then(response => response.json())
        .then(products => {
            renderProducts(products);
        })
        .catch(err => console.error('Error fetching products:', err));
}

// Render products dynamically on the page
function renderProducts(products) {
    const productContainer = document.getElementById("product-container");
    productContainer.innerHTML = ""; // Clear previous content

    products.forEach(product => {
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

// Handle page load based on current URL
function handlePageLoad() {
    const path = window.location.pathname.substring(1); // Get the path without "/"
    const category = path || 'home'; // Default to 'home' if no category
    fetchAndRenderProducts(category);
}

// Handle clicks on navigation links
document.querySelectorAll("nav a").forEach(navLink => {
    navLink.addEventListener("click", (e) => {
        e.preventDefault();
        const href = e.target.getAttribute("href").substring(1); // Get category from href
        history.pushState({}, '', `/${href}`); // Update URL without reloading
        fetchAndRenderProducts(href); // Fetch products for the new category
    });
});

// Load products on initial page load
window.addEventListener("load", handlePageLoad);
