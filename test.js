// const rawstr = 'name:Alexander;position:CTO;job:New.HR';
// console.log(JSON.parse(`{"${rawstr.replace(/;|:/g,s=>`"${s==';'?',':s}"`)}"}`))
// console.log(rawstr.split(/;|:/).reduce((o,c,i,a)=>i%2?(o[a[i-1]]=c,o):o,{}))

// const numfix = (n, t) => t[ ([,1,2,2,2][20 > n && n > 4 ? 0 : n % 10] || 3) - 1 ];
// for ( let i=0; i<150 ; i++) {
//   console.log(i,numfix(i, ['день','дня','дней']))
// }


// { name: 'Alexander', position: 'CTO', job: 'New.HR' }


// for(A in {A󠅬󠅷󠅡󠅹󠅳󠄠󠅢󠅥󠄠󠅷󠅡󠅲󠅹󠄠󠅯󠅦󠄠󠅊󠅡󠅶󠅡󠅳󠅣󠅲󠅩󠅰󠅴󠄠󠅣󠅯󠅮󠅴󠅡󠅩󠅮󠅩󠅮󠅧󠄠󠅱󠅵󠅯󠅴󠅥󠅳󠄮󠄠󠅎󠅯󠄠󠅱󠅵󠅯󠅴󠅥󠅳󠄠󠄽󠄠󠅳󠅡󠅦󠅥󠄡:0}){console.log(unescape(escape(A).replace(/u.{8}/g,[])))};

const code = s =>
  unescape(
    [...s].reduce((s,c) => `${s}%uDB40%uDD${c.charCodeAt().toString(16)}`)
  )
;
// var a = code('Hello, Habrahabr from Tutu.ru!');
// console.log(a.length)
// console.log(a)

// console.log(unescape(escape(a).replace(/u.{8}/g,[])))





// const numfix = (n, t) => t[
//   (n %= 100, 20 > n && n > 4) ? 2 :[2,0,1,1,1,2][ (n %= 10, n < 5) ? n : 5]
// ]
// ;



var cat = {
  lives: 9,
  jumps() {
    console.log(this )
    this.lives--;
  }
};
console.log(cat.lives); // => 9
const jump = cat.jumps;
jump();
console.log(cat.lives); // => все еще 9
