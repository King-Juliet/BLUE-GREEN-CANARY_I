const products = [
  { id: 1, name: "Green Ceramic Bottle", category: "Lifestyle", price: 34, emoji: "🌿" },
  { id: 2, name: "Everyday Candle", category: "Home", price: 18, emoji: "🕯️" },
  { id: 3, name: "Desk Lamp", category: "Office", price: 42, emoji: "💡" },
  { id: 4, name: "Glow Skin Kit", category: "Beauty", price: 29, emoji: "✨" },
  { id: 5, name: "Daily Cotton Set", category: "Lifestyle", price: 26, emoji: "🧺" },
  { id: 6, name: "Minimal Chair", category: "Home", price: 76, emoji: "🪑" },
  { id: 7, name: "Focus Journal", category: "Office", price: 14, emoji: "📓" },
  { id: 8, name: "Harvest Basket", category: "Home", price: 38, emoji: "🧺" }
];

const state = {
  cart: [],
  selectedProduct: products[0].id
};

const productGrid = document.getElementById("productGrid");
const productSelect = document.getElementById("productSelect");
const checkoutItems = document.getElementById("checkoutItems");
const cartCount = document.getElementById("cartCount");
const checkoutButton = document.getElementById("checkoutButton");
const orderForm = document.getElementById("orderForm");
const sortSelect = document.getElementById("sortSelect");
const apiStatus = document.getElementById("apiStatus");

function renderProducts(items = products) {
  productGrid.innerHTML = "";
  items.forEach((product) => {
    const card = document.createElement("article");
    card.className = "product-card";
    card.innerHTML = `
      <div class="product-image">${product.emoji}</div>
      <div class="product-info">
        <span class="product-category">${product.category}</span>
        <div class="product-name">${product.name}</div>
        <div class="product-price">$${product.price}</div>
      </div>
      <div class="product-card-footer">
        <span class="product-version">v${product.id % 3 || 1}</span>
        <button data-id="${product.id}">Add</button>
      </div>
    `;
    productGrid.appendChild(card);
  });

  productGrid.querySelectorAll("button[data-id]").forEach((button) => {
    button.addEventListener("click", () => {
      const product = products.find((p) => p.id === Number(button.dataset.id));
      if (product) {
        state.cart.push(product.id);
        cartCount.textContent = String(state.cart.length);
        renderCheckout();
      }
    });
  });
}

function renderProductOptions() {
  productSelect.innerHTML = products
    .map((product) => `<option value="${product.id}">${product.name} - $${product.price}</option>`)
    .join("");
  productSelect.value = String(products[0].id);
}

function renderCheckout() {
  if (state.cart.length === 0) {
    checkoutItems.innerHTML = `<div class="empty-cart">No items added yet.</div>`;
    return;
  }

  const selected = products.filter((product) => state.cart.includes(product.id));
  const total = selected.reduce((sum, product) => sum + product.price, 0);
  checkoutItems.innerHTML = selected
    .map((product) => `<div class="checkout-line"><span>${product.name}</span><span>$${product.price}</span></div>`)
    .join("") + `<div class="checkout-line"><strong>Total</strong><strong>$${total}</strong></div>`;
}

function sortProducts(mode) {
  let items = [...products];
  if (mode === "low-high") {
    items.sort((a, b) => a.price - b.price);
  } else if (mode === "high-low") {
    items.sort((a, b) => b.price - a.price);
  }
  renderProducts(items);
}

shopNow.addEventListener("click", () => {
  document.querySelector(".shop-panel").scrollIntoView({ behavior: "smooth" });
});

previewDeals.addEventListener("click", () => {
  sortSelect.value = "high-low";
  sortProducts("high-low");
});

sortSelect.addEventListener("change", () => {
  sortProducts(sortSelect.value);
});

checkoutButton.addEventListener("click", async () => {
  apiStatus.textContent = "Checking out...";
  try {
    const response = await fetch("/api/health");
    const body = await response.json();
    apiStatus.textContent = body.status;
  } catch (error) {
    apiStatus.textContent = "Backend offline";
  }
});

orderForm.addEventListener("submit", async (event) => {
  event.preventDefault();

  const payload = {
    customerName: document.getElementById("customerName").value,
    customerEmail: document.getElementById("customerEmail").value,
    city: document.getElementById("city").value,
    productId: Number(productSelect.value)
  };

  apiStatus.textContent = "Submitting order...";

  try {
    const response = await fetch("/api/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });

    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message || "Order failed");
    }

    apiStatus.textContent = `Order ${data.order.id} created`;
    state.cart = [];
    cartCount.textContent = "0";
    renderCheckout();
  } catch (error) {
    apiStatus.textContent = error.message;
  }
});

renderProducts();
renderProductOptions();
renderCheckout();
