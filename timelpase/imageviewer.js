import { downloadZip } from "https://cdn.jsdelivr.net/npm/client-zip/index.js"

let frame = 0;
let lastframe = 0;
let pauseframe = 0;
let interval = 500;
//let base = '%s';
//let folder;// = '%s';
let url;// = 'http://'+base+'/fs'+folder;
let pic;
let framespan;
let framedisplay;
let framedone = 1;
let framecount = 1;

let currfolder;
let currfolderabs;

function pause(){
  pauseframe = 1;
}
window.pause = pause;
function resume(){
  pauseframe = 0;
}
window.resume = resume;
function restart(){
  pauseframe = 0;
  frame = 0;
}
window.restart = restart;
function incr(){
  if (+frame < +framecount-1){
    frame = +frame + 1;
    slider.value = +frame;
  }
}
window.incr= incr;
function decr(){
  if (+frame > 0){
    frame = +frame - 1;
    slider.value = +frame;
  }
}
window.decr=decr;
let frametimer;
function showframe(){
    if (!frametimer){
      frametimer = setTimeout(async ()=>{
        clearTimeout(frametimer);
        frametimer = null;
        if (!framedone){
          // if we did not get the last frame, just wait a little longer.
          console.log('waiting last complete');
          showframe();
          return;
        }
        lastframe = frame;
        let jsonData = {time:'unknown'};
        try{
          const response = await fetch(url+'frame'+frame+'.json');
          jsonData = await response.json();
          console.log(jsonData);
        } catch(e){
          console.error(e);
        }
        pic.src = url+'frame'+frame+'.jpg';
        framedone = 0;
        framespan.innerText = frame+':'+jsonData.time;
        if (jsonData.val){
          framespan.innerText += ' Mvmt:'+jsonData.val; 
        }
        framedisplay.innerText = ''+frame + '/'+slider.max;
      }, 100);
    }
  }

function sliderchange(val){
  frame = +val;
  showframe();
}
window.sliderchange = sliderchange;
function intervalchange(val){
  interval = +val;
  let f = document.getElementById('frameinterval');
  f.innerText = 'Frame Interval:'+interval;
}
window.intervalchange = intervalchange;
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

window.onload=()=>{
  pic = document.getElementById('image')
  framespan = document.getElementById('frame')
  framedisplay = document.getElementById('framecounter');
  let slider = document.getElementById('slider');
  framedone = 1;

  pic.onload =()=>{
    framedone = 1;
  };
  pic.onerror =()=>{
    framedone = 1;
  };

  async function download(){
    pause();
    let src = url;
    let filelist = [];
    let download = document.getElementById('downloading');

    for (let i = 0; i < framecount-1; i++){
      filelist.push({name:'frame'+i+'.json', url:url+'frame'+i+'.json'});
      filelist.push({name:'frame'+i+'.jpg', url:url+'frame'+i+'.jpg'});
    }
    console.log(filelist);

    let promises = [];
    for (let i = 0; i < filelist.length; i++){
      try{
        let promise = fetch(filelist[i].url);
        let response = await promise;
        promises.push({name:filelist[i].name, input:response});
        download.innerText = 'downloaded '+ filelist[i].name+' '+i+'/'+filelist.length;
      }catch(e){
        console.error(e, filelist[i]);
      }
    }
    const blob = await downloadZip(promises).blob()
  
    const link = document.createElement("a")
    link.href = URL.createObjectURL(blob)
    link.download = "images.zip"
    link.click()
  }

  async function doit(){
      let folderesp = await fetch('./folders.json');
      const folders = await folderesp.json();

      async function seturl(f){
          currfolder = f;
          url = './'+f+'/';
          try{
              const response = await fetch(url+'config.json');
              const jsonData = await response.json();
              //console.log(jsonData);
              framecount = jsonData.frame;
              currfolderabs = jsonData.currfolder;
              if (currfolderabs.endsWith('/')){
                currfolderabs = currfolderabs.slice(0, -1);
              }
              // framecount is the NEXT frame it will capture.
              slider.max = +framecount-2;
              lastframe = 0;
              let folderel = document.getElementById('folder');
              folderel.innerText = f;
              framedisplay.innerText = ''+frame + '/'+slider.max;
              return true;
          } catch(e) {
              return false;
          }
      };

      if (folders.folders){
          for (let i = 0; i < folders.folders.length; i++){
              if (await seturl(folders.folders[i])){
                  break;
              }
          }
      }

      let foldersel = document.getElementById('folders');
      for (let i = 0; i < folders.folders.length; i++){
          let f = folders.folders[i];
          let b = document.createElement('BUTTON');
          b.innerText = f;
          b.onclick = async (ev)=>{
              if (ev.altKey){
                  if (window.confirm('Do you wish to delete "'+f+'" and all contents?')){
                      await seturl(f); // sets currfolderabs
                      //http://192.168.1.190/cs?c2=166&c1=zapfolder%20test
                      let tascmd = 'http://'+location.host+'/cm?cmnd=zapfolder%20'+currfolderabs;
                      let resp = await fetch(tascmd)
                      const res = await resp.text();
                      console.log(res);
                      // force a refresh in 3s, after TAS has updated out folder list
                      setTimeout(()=>{
                          window.location = window.location;
                      }, 3000)
                  }
              }else {
                if (ev.ctrlKey){
                  if (window.confirm('Do you wish to download "'+f+'" and all contents?')){
                    await seturl(f);
                    download(f);
                  }
                } else {
                  await seturl(f);
                }
              }
          };
          foldersel.appendChild(b);
      }

      let updatecounter = 10;

      while (1){
        if (!pauseframe || (+frame !== +lastframe)){
          showframe();
        }
        await sleep(interval);

        updatecounter--;
        if (!updatecounter){
          // refresh our total available frames
          try{
              const response = await fetch(url+'config.json');
              const jsonData = await response.json();
              //console.log(jsonData);
              let slider = document.getElementById('slider');
              framecount = +jsonData.frame;
              // framecount is the NEXT frame it will capture.
              slider.max = framecount-2;
              framedisplay.innerText = ''+frame + '/'+slider.max;
              updatecounter = 10;
          } catch(e){
            console.error(e);
          }
        }
        if (frame == framecount-1){
          pauseframe = 1;
        }
        if (!pauseframe){
          incr();
        }
      }
      pic.src = null;
  }
  doit();
};
