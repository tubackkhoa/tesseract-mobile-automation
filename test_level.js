var level = require('level')

// 1) Create our database, supply location and options.
//    This will create or open the underlying store.
var db = level('mt4')


// const run = async  (key)=>{
//     // await db.put(key, JSON.stringify(value || 'Level'))
//     let value;
//     try{
//      value = await db.get(key)
//     } catch(ex){

//     }
//     console.log('value', value)
// }


// run('trade.2175994')
// run('trade.2175996')
// run('trade.2176034')

db.put(`trade.5012315`, "ignore");
