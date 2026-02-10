<script setup>
import { ref, onMounted, reactive } from 'vue';
import axios from 'axios';

const API_BASE_URL = 'http://book-keeping-backend.lollipopzzz.cn';

// Data models
const customers = ref([]);
const trunkModels = ref([]);

// Form State
const form = reactive({
  date: new Date().toISOString().substr(0, 10),
  customer_name: '',
  trunk_model: '',
  construction_site: '',
  quantity: 0,
  price: 0,
  charged: false,
  remark: ''
});

// Loading/Error states
const loading = ref(false);
const error = ref(null);
const success = ref(false);

// Add New State
const newCustomerName = ref('');
const showAddCustomer = ref(false);
const newTrunkModelName = ref('');
const showAddTrunkModel = ref(false);

// API Client
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Lifecycle
onMounted(async () => {
  await fetchData();
});

const fetchData = async () => {
  try {
    const [custRes, modelRes] = await Promise.all([
      api.get('/api/customers'),
      api.get('/api/models')
    ]);
    customers.value = custRes.data;
    trunkModels.value = modelRes.data;
  } catch (err) {
    console.error('Failed to load data', err);
    error.value = 'Failed to load options from backend (' + API_BASE_URL + ').';
  }
};

// Actions
const submitForm = async () => {
  loading.value = true;
  error.value = null;
  success.value = false;
  
  try {
    // Validate
    if (!form.customer_name || !form.trunk_model) {
      throw new Error('Please select customer and trunk model');
    }

    const payload = { ...form };
    // Ensure numbers
    payload.quantity = parseInt(payload.quantity);
    payload.price = parseInt(payload.price);

    await api.post('/api/records', payload);
    success.value = true;
    
    // Clear numeric fields but keep date, site maybe?
    form.quantity = 0;
    form.price = 0;
  } catch (err) {
    console.error('Submit error', err);
    // Determine error message
    const msg = err.response?.data?.error || err.message || 'Submission failed';
    error.value = msg;
  } finally {
    loading.value = false;
  }
};

const addCustomer = async () => {
  if (!newCustomerName.value) return;
  try {
    await api.post('/api/customers', { customer_name: newCustomerName.value });
    await fetchData(); // Refresh list
    form.customer_name = newCustomerName.value; // Auto select
    newCustomerName.value = '';
    showAddCustomer.value = false;
  } catch (err) {
    alert('Failed to add customer: ' + (err.response?.data?.error || err.message));
  }
};

const addTrunkModel = async () => {
  if (!newTrunkModelName.value) return;
  try {
    await api.post('/api/models', { trunk_model: newTrunkModelName.value });
    await fetchData(); // Refresh list
    form.trunk_model = newTrunkModelName.value; // Auto select
    newTrunkModelName.value = '';
    showAddTrunkModel.value = false;
  } catch (err) {
    alert('Failed to add model: ' + (err.response?.data?.error || err.message));
  }
};
</script>

<template>
  <div class="form-wrapper">
    <div v-if="error" class="error-msg">{{ error }}</div>
    <div v-if="success" class="success-msg">Record saved successfully!</div>

    <form @submit.prevent="submitForm">
      
      <!-- Date -->
      <div class="form-group">
        <label>Date</label>
        <input type="date" v-model="form.date" required />
      </div>

      <!-- Customer -->
      <div class="form-group">
        <label>Customer</label>
        <div class="radio-group" v-if="customers.length > 0">
          <label v-for="c in customers" :key="c.id" class="radio-label">
            <input type="radio" :value="c.customer_name" v-model="form.customer_name" />
            {{ c.customer_name }}
          </label>
        </div>
        <div v-else class="empty-hint">No customers found.</div>
        
        <div class="add-section">
          <button type="button" @click="showAddCustomer = !showAddCustomer" class="add-btn">
            {{ showAddCustomer ? 'Cancel' : '+ Add Customer' }}
          </button>
          <div v-if="showAddCustomer" class="add-box">
            <input v-model="newCustomerName" placeholder="New Customer Name" />
            <button type="button" @click="addCustomer" class="save-small-btn">Save</button>
          </div>
        </div>
      </div>

      <!-- Trunk Model -->
      <div class="form-group">
        <label>Trunk Model</label>
        <div class="radio-group" v-if="trunkModels.length > 0">
          <label v-for="m in trunkModels" :key="m.id" class="radio-label">
            <input type="radio" :value="m.trunk_model" v-model="form.trunk_model" />
            {{ m.trunk_model }}
          </label>
        </div>
         <div v-else class="empty-hint">No models found.</div>

        <div class="add-section">
          <button type="button" @click="showAddTrunkModel = !showAddTrunkModel" class="add-btn">
            {{ showAddTrunkModel ? 'Cancel' : '+ Add Model' }}
          </button>
          <div v-if="showAddTrunkModel" class="add-box">
            <input v-model="newTrunkModelName" placeholder="New Model Name" />
            <button type="button" @click="addTrunkModel" class="save-small-btn">Save</button>
          </div>
        </div>
      </div>

      <!-- Construction Site -->
      <div class="form-group">
        <label>Construction Site</label>
        <input type="text" v-model="form.construction_site" required />
      </div>

      <!-- Quantity & Price -->
      <div class="row">
        <div class="form-group half">
          <label>Quantity</label>
          <input type="number" v-model.number="form.quantity" required min="1" />
        </div>
        <div class="form-group half">
          <label>Price</label>
          <input type="number" v-model.number="form.price" required min="0" />
        </div>
      </div>

      <!-- Charged -->
      <div class="form-group checkbox-group">
        <label>
          <input type="checkbox" v-model="form.charged" />
          Is Charged?
        </label>
      </div>

      <!-- Remark -->
      <div class="form-group">
        <label>Remark</label>
        <textarea v-model="form.remark"></textarea>
      </div>

      <button type="submit" :disabled="loading" class="submit-btn">
        {{ loading ? 'Submitting...' : 'Create Record' }}
      </button>
    </form>
  </div>
</template>

<style scoped>
.form-wrapper {
  background: #2a2a2a;
  padding: 2rem;
  border-radius: 8px;
  text-align: left;
  max-width: 600px;
  margin: 0 auto;
}
.form-group {
  margin-bottom: 1.5rem;
}
label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
  color: #ddd;
}
input[type="text"],
input[type="date"],
input[type="number"],
textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #555;
  background: #333;
  color: white;
  border-radius: 4px;
  box-sizing: border-box;
}
textarea {
  min-height: 80px;
}
.radio-group {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 10px;
}
.radio-label {
  background: #3a3a3a;
  padding: 8px 12px;
  border-radius: 20px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  font-weight: normal;
  border: 1px solid #444;
  transition: all 0.2s;
}
.radio-label:hover {
  background: #444;
}
.radio-label:has(input:checked) {
  background: #42b983; /* Vue Green */
  color: white;
  border-color: #42b983;
}
.radio-label input {
  margin: 0;
}
.add-section {
  margin-top: 5px;
}
.add-btn {
  background: transparent;
  border: 1px dashed #777;
  color: #ccc;
  cursor: pointer;
  padding: 5px 10px;
  font-size: 0.9em;
  border-radius: 4px;
}
.add-btn:hover {
  border-color: #fff;
  color: #fff;
}
.add-box {
  margin-top: 10px;
  display: flex;
  gap: 5px;
}
.save-small-btn {
  background: #42b983;
  border: none;
  color: white;
  padding: 0 15px;
  border-radius: 4px;
  cursor: pointer;
}
.submit-btn {
  width: 100%;
  padding: 12px;
  background: #646cff; /* Vite blue */
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1.1rem;
  font-weight: bold;
  cursor: pointer;
  transition: background 0.2s;
}
.submit-btn:hover {
  background: #535bf2;
}
.submit-btn:disabled {
  background: #444;
  cursor: not-allowed;
}
.error-msg {
  color: #ff6b6b;
  margin-bottom: 1rem;
  padding: 10px;
  background: rgba(255, 0, 0, 0.1);
  border-left: 4px solid #ff6b6b;
}
.success-msg {
  color: #4CAF50;
  margin-bottom: 1rem;
  padding: 10px;
  background: rgba(76, 175, 80, 0.1);
  border-left: 4px solid #4CAF50;
}
.row {
  display: flex;
  gap: 1rem;
}
.half {
  flex: 1;
}
.checkbox-group label {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  font-weight: normal;
}
.empty-hint {
  color: #888;
  font-style: italic;
  font-size: 0.9em;
  margin-bottom: 5px;
}
</style>
