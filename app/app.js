const express = require('express');
const { MongoClient } = require('mongodb');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = 3000;

// Récupérer l'URI MongoDB depuis la variable d'environnement
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://admin:P@ssw0rd123@localhost:27017/';

let db;
let todosCollection;

// Connexion à MongoDB
MongoClient.connect(MONGODB_URI, { 
  useNewUrlParser: true, 
  useUnifiedTopology: true 
})
.then(client => {
  console.log('✅ Connected to MongoDB');
  db = client.db('tododb');
  todosCollection = db.collection('todos');
})
.catch(error => {
  console.error('❌ MongoDB connection error:', error);
  process.exit(1);
});

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Servir les fichiers statiques
app.use(express.static(__dirname));

// Route principale - Servir le HTML
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Route pour wizexercice.txt
app.get('/wizexercice.txt', (req, res) => {
  res.sendFile(path.join(__dirname, 'wizexercice.txt'));
});

// API - Récupérer tous les todos
app.get('/api/todos', async (req, res) => {
  try {
    const todos = await todosCollection.find({}).toArray();
    res.json(todos);
  } catch (error) {
    console.error('Error fetching todos:', error);
    res.status(500).json({ error: 'Failed to fetch todos' });
  }
});

// API - Ajouter un todo
app.post('/api/todos', async (req, res) => {
  try {
    const { text } = req.body;
    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }
    
    const newTodo = {
      text: text,
      done: false,
      createdAt: new Date()
    };
    
    const result = await todosCollection.insertOne(newTodo);
    res.json({ ...newTodo, _id: result.insertedId });
  } catch (error) {
    console.error('Error adding todo:', error);
    res.status(500).json({ error: 'Failed to add todo' });
  }
});

// API - Marquer un todo comme fait/non fait
app.put('/api/todos/:id', async (req, res) => {
  try {
    const { ObjectId } = require('mongodb');
    const id = new ObjectId(req.params.id);
    const { done } = req.body;
    
    await todosCollection.updateOne(
      { _id: id },
      { $set: { done: done } }
    );
    
    res.json({ success: true });
  } catch (error) {
    console.error('Error updating todo:', error);
    res.status(500).json({ error: 'Failed to update todo' });
  }
});

// API - Supprimer un todo
app.delete('/api/todos/:id', async (req, res) => {
  try {
    const { ObjectId } = require('mongodb');
    const id = new ObjectId(req.params.id);
    
    await todosCollection.deleteOne({ _id: id });
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting todo:', error);
    res.status(500).json({ error: 'Failed to delete todo' });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', mongodb: db ? 'connected' : 'disconnected' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Todo app listening on port ${PORT}`);
});