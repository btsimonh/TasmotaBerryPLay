import { downloadZip } from "https://cdn.jsdelivr.net/npm/client-zip/index.js"

let frame = 0;
let lastframe = 0;
let pauseframe = 0;
let interval = 1000;
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
  if (+frame < +framecount){
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
        // syncronously get the json and image data
        clearTimeout(frametimer);
        // value of frame at start of sync get
        let f = frame;
        if (!framedone){
          // if we did not get the last frame, just wait a little longer.
          console.log('waiting last complete');
          showframe();
          return;
        }
        lastframe = f;
        let jsonData = {time:'unknown'};
        try{
          const response = await fetch(url+'frame'+f+'.json');
          jsonData = await response.json();
          console.log(jsonData);
        } catch(e){
          console.error(e);
        }
        let picurl = url+'frame'+f+'.jpg';
        let picresp = await fetch(picurl)
        let picblob = await picresp.blob();
        let picURL = URL.createObjectURL(picblob);

        pic.src = picURL;
        framedone = 0;
        framespan.innerText = f+':'+jsonData.time;
        if (jsonData.val){
          framespan.innerText += ' Mvmt:'+jsonData.val; 
        }
        framedisplay.innerText = ''+f + '/'+slider.max;
        frametimer = null;
      }, 10);
    }
  }

function sliderchange(val){
  frame = +val;
  framedisplay.innerText = ''+frame + '/'+slider.max;
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

    for (let i = 0; i < framecount; i++){
      filelist.push({name:'frame'+i+'.json', url:url+'frame'+i+'.json'});
      filelist.push({name:'frame'+i+'.jpg', url:url+'frame'+i+'.jpg'});
    }
    console.log(filelist);

    let inputs = [];
    for (let i = 0; i < filelist.length; i++){
      try{
        let promise = fetch(filelist[i].url);
        let response = await promise;
        // get the blob here so that the transaction is completed, and
        // we only have one transaction at a time against tas.
        let blob = await response.blob();

        inputs.push({name:filelist[i].name, input:blob});
        download.innerText = 'downloaded '+ filelist[i].name+' '+i+'/'+filelist.length;
      }catch(e){
        console.error(e, filelist[i]);
      }
    }
    const blob = await downloadZip(inputs).blob()
  
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
              slider.max = +framecount-1;
              lastframe = 0;
              let folderel = document.getElementById('folder');
              folderel.innerText = f;
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
              slider.max = framecount-1;
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
