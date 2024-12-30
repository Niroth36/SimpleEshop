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
            console.log("Rendering products for category:", category, products); // Debug log

            if (products.length === 0) {
                dynamicContent.innerHTML = "<p>No products available in this category.</p>";
                return;
            }

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
                dynamicContent.appendChild(productDiv);
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

// Handle page load to render the appropriate content
function handlePageLoad() {
    const path = window.location.pathname.substring(1); // Get the path without "/"
    const category = path || "home"; // Default to 'home' if no category
    renderContent(category);
}

// Handle clicks on navigation links
document.querySelectorAll("nav a").forEach(navLink => {
    navLink.addEventListener("click", (e) => {
        e.preventDefault();
        const href = e.target.getAttribute("href").substring(1); // Get category from href
        history.pushState({}, '', `/${href}`); // Update URL without reloading
        renderContent(href); // Render content for the new category
    });
});

// Handle browser navigation (back/forward buttons)
window.addEventListener("popstate", handlePageLoad);

// Initial load
window.addEventListener("load", handlePageLoad);
