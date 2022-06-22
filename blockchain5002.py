##CREATING CRYPTOCURRENCY
import datetime
import hashlib
import json
from flask import Flask, jsonify,request
import requests
from uuid import uuid4
from urllib.parse import urlparse

class Blockchain:
    def __init__(self):
        self.chain=[]
        self.transactions=[]
        self.create_block(proof=1,prev_hash='0')
        self.nodes = set()
        
    def create_block(self,proof,prev_hash):
        block = {'index':len(self.chain) + 1,
               'timestamp':str(datetime.datetime.now()),
               'proof':proof,
               'prev_hash':prev_hash,
               'txn':self.transactions}##creating dictionary
        self.transactions = []
        self.chain.append(block)
        return block
    def get_prev_block(self):
        return self.chain[-1]
    
    def proof_of_work(self, prev_proof):
        new_proof = 1
        check_proof=False
        while  check_proof is False:
            hash_opr = hashlib.sha256(str(new_proof**2 - prev_proof**2).encode()).hexdigest()
            ##print(hash_opr)
            if hash_opr[:4] == "0000":
               check_proof=True
            else:
                new_proof += 1
                
        return new_proof 
    def hash(self,block):
        encoded_block = json.dumps(block,sort_keys = True).encode()
        return hashlib.sha256(encoded_block).hexdigest()
    def is_chain_valid(self,chain):
        prev_block=chain[0]
        block_index=1
        while block_index < len(chain):
            block = chain[block_index]
            if block['prev_hash']!=self.hash(prev_block):
                return False
            prev_proof = prev_block['proof']
            proof =block['proof']
            hash_opr=hashlib.sha256(str(proof**2 - prev_proof**2).encode()).hexdigest()
        
            if hash_opr[:4]!= '0000':
                return False
            prev_block=block
            block_index+=1
        return True
    def faultyblockindex(self,chain):
        prev_block=chain[0]
        block_index=1
        while block_index < len(chain):
            if chain[block_index]['prev_hash']!=self.hash(prev_block):
                return chain[block_index]['index']
            hash_opr=hashlib.sha256(str(chain[block_index]['proof']**2 -prev_block['proof']**2).encode()).hexdigest()
            ##print(hash_opr)
            if hash_opr[:4]!='0000':
                return chain[block_index]['index']
            prev_block=chain[block_index]
            block_index+=1
        return -1
    def add_transaction(self,sender,receiver,amount):
        txn={'sender':sender,
             'receiver':receiver,
             'amount':amount}
        self.transactions.append(txn)
        network=self.nodes
        for node in network:
            requests.post(f'http://{node}/add_transaction',data=txn)
        return self.get_prev_block()['index']+1
    def add_node(self,address):
        parsed_url=urlparse(address)
        self.nodes.add(parsed_url.netloc+parsed_url.path.replace('/',':'))
    def longest_chain_cnt(self,max_length):
         network=self.nodes
         own_len=len(self.chain)
         longest_chain_list=[]
         cnt=0
         if own_len == max_length:
            cnt+=1
            longest_chain_list.append(self.chain)
         for node in network:
             response=requests.get(f'http://{node}/get_chain')
             if response.status_code==200:
                if response.json()['length'] == max_length and self.is_chain_valid(response.json()['chain']):
                    cnt+=1
                    if response.json()['chain'] not in longest_chain_list:
                        longest_chain_list.append(response.json()['chain'])
                    ##longest_chain_set.add(response.json()['chain'])
         return cnt,longest_chain_list
    
    def replace_chain(self):
        longest_chain=self.chain
        max_chain_length=len(self.chain)
        network=self.nodes
        for node in network:
            response = requests.get(f'http://{node}/get_chain')
            if response.status_code == 200:
                length=response.json()['length']
                chain=response.json()['chain']
                if length > max_chain_length and self.is_chain_valid(chain):
                   ## if length == max_chain_length:
                     ##   return "MORE THEN ONE NODES HAVE SAME NUMBER OF NEW BLOCKS.",False
                    max_chain_length=length
                    longest_chain=chain
        if longest_chain:
            cnt,longest_chain_list=self.longest_chain_cnt(max_chain_length)
            if cnt>1 and len(longest_chain_list)>1:
                 return "MORE THEN ONE NODES HAVE SAME NUMBER OF NEW BLOCKS, BUT HAVING DIFFERENT BLOCKS ",False
            else:
                if self.chain==longest_chain:
                    return "ALL GOOD.THE EXISTING CHAIN IS THE LONGEST ONE",False
                else:
                    self.chain=longest_chain
                    return "THE NODES HAD DIFFERENT CHAINS SO THE CHAIN WAS REPLACED WITH THE LONGEST ONES.",True
        
    
   
     
            
        
        
                
app=Flask(__name__)
node_address=str(uuid4()).replace('-','')##creating an address for the node on port 5000
blockchain=Blockchain()##creating object##creating a blockchain


@app.route('/mine_block',methods = ['GET'])
def mine_block():
    if len(blockchain.transactions)>0:
            prev_block=blockchain.get_prev_block()
            prev_proof=prev_block['proof']
            proof=blockchain.proof_of_work(prev_proof)
            prev_hash=blockchain.hash(prev_block)
            ##blockchain.add_transaction(sender=node_address,receiver='Ramya',amount=1)
            block=blockchain.create_block(proof,prev_hash)
   ## block_hash=blockchain.hash(block)
            response= {'message': 'Congrats, You just mined a block!!!!',
                       'index': block['index'],
                       'timestamp': block['timestamp'],
                       'proof': block['proof'],
                       'prev_hash': block['prev_hash'],
                       'txns':block['txn']
                       }
    else:
            response={'message':'NO TRANSACTIONS IN MEMPOOL'
                  }
    return jsonify(response), 200

@app.route('/get_chain',methods = ['GET'])
def get_chain():
    response = {'chain': blockchain.chain, ##list
                'length': len(blockchain.chain)}
    return jsonify(response), 200


@app.route('/add_transaction',methods = ['POST'])
def add_transaction():
    json=request.get_json()##to get the i/p in json format
    transaction_keys=['sender','receiver','amount']##list of 3 keys of a transaction
    if not all(key in json for key in transaction_keys):##if all the keys in transaction keys list  are not in json file 
        return 'some elements are missing',400
    index=blockchain.add_transaction(json['sender'],json['receiver'],json['amount'])
    response = {'messsage':f'This transaction will be added to Block {index}'}
    return jsonify(response),201

@app.route('/connect_node',methods = ['POST'])
def connect_node():
    json=request.get_json()
    nodes=json.get('nodes')
    if nodes is None:
        return 'No Node',400
    for node in nodes:
        blockchain.add_node(node)
    return jsonify({'message':'All nodes are now connected.The Ditcoin contains the following nodes:',
                    'total_nodes':list(blockchain.nodes)
                    }
                  ),201
    
    
@app.route('/validity',methods = ['GET'])
def is_valid():
    if blockchain.is_chain_valid(blockchain.chain):
        return jsonify({'message':'Hell Yeah!!! it is valid'}),200
    else:
        blockindex=blockchain.faultyblockindex(blockchain.chain)
        if blockindex == -1:
            return jsonify({'message':'CRAP..Chain isnt valid anymore.Unable to find with block'}),200
        else:
            return jsonify({'message':'CRAP..Chain isnt valid anymore','BLOCK INDEX':blockindex}),200
        

@app.route('/replace_chain',methods = ['GET'])
def is_chain_replaced():
    msg,bol=blockchain.replace_chain()
    if bol:
        return jsonify({'message':msg,
                  'new chain':blockchain.chain}),200
    return jsonify({'message':msg,
                  'chain':blockchain.chain}),200
        
@app.route('/get_all_hash',methods = ['GET'])   
def get_all_hash():
    block_index=0
    allhashes=[]
    while block_index<len(blockchain.chain):
        allhashes.append(blockchain.hash(blockchain.chain[block_index]))
        block_index+=1
    return jsonify({'All_Hashes':allhashes,
                    'total':len(allhashes)}),200
        
@app.route('/get_mempool',methods =['GET'])
def get_transactions():
    if len(blockchain.transactions)>0:
        next_index=blockchain.get_prev_block()['index']+1
        return jsonify({'message':f'TRANSACTION(S) YET TO BE ADDED TO {next_index}',
                    'txn[]':list(blockchain.transactions)
                    }),200
    else:
        return jsonify({'message':'No Transactions'
                    }),200
        
app.run(host='0.0.0.0',port= 5002)


        